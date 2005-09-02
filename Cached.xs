/*
	context marshalling massively pessimizes extensions built for threaded perls e.g. Cygwin.

	define PERL_CORE rather than PERL_NO_GET_CONTEXT (see perlguts) because a) PERL_GET_NO_CONTEXT still incurs the
	overhead of an extra function call for each interpreter variable; and b) this is a drop-in replacement for a
	core op.
*/

#define PERL_CORE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

OP* goto_cached_static(pTHX);
OP* goto_cached_dynamic(pTHX);
OP *goto_cached_check(pTHX_ OP *o);
OP* goto_cached_static_cached(pTHX);

static U32 GOTO_CACHED_SCOPE_DEPTH = 0;
static AV *GOTO_CACHED_ALLOCATED_HASHES = NULL;
static U8 GOTO_CACHED_CACHED = 128;

OP* goto_cached_static_cached(pTHX) {
	return (PL_op->op_next);
}

OP* goto_cached_static(pTHX) {
	OP *op;
	op = Perl_pp_goto(aTHX);

	if (PL_lastgotoprobe) { /* target is not in scope */
		PL_op->op_ppaddr = MEMBER_TO_FPTR(Perl_pp_goto);
	} else {
		PL_op->op_next = op;
		PL_op->op_ppaddr = goto_cached_static_cached;
	}

	return op;
}

OP* goto_cached_dynamic(pTHX) {
	dSP;
	SV *sv = TOPs;
	OP *op = NULL;
	size_t len;
	char *label = SvPV(sv, len);

	if (SvROK(sv)) {
		PL_op->op_private &= ~GOTO_CACHED_CACHED;
		PL_op->op_ppaddr = MEMBER_TO_FPTR(Perl_pp_goto);
		return Perl_pp_goto(aTHX);
	} else if (PL_op->op_private & GOTO_CACHED_CACHED) {
		SV **svp;

		svp = hv_fetch((HV *)PL_op->op_next, label, len, 0);

		if (svp && *svp && SvOK(*svp)) {
			RETURNOP(INT2PTR(OP *, SvIVX(*svp)));
		} else {
			op = Perl_pp_goto(aTHX);
			if (PL_lastgotoprobe) { /* target is not in scope */
				PL_op->op_private &= ~GOTO_CACHED_CACHED;
				PL_op->op_ppaddr = MEMBER_TO_FPTR(Perl_pp_goto);
			} else {
				hv_store((HV *)PL_op->op_next, label, len, newSVuv(PTR2UV(op)), 0);
			}
			return op;
		}
	} else {
		op = Perl_pp_goto(aTHX);
		if (PL_lastgotoprobe) { /* target is not in scope */
			PL_op->op_ppaddr = MEMBER_TO_FPTR(Perl_pp_goto);
		} else {
			HV * hv;
			hv = newHV();
			PL_op->op_next = (OP *)hv;
			HvSHAREKEYS_off(hv);
			av_push(GOTO_CACHED_ALLOCATED_HASHES, (SV *)hv);
			PL_op->op_private |= GOTO_CACHED_CACHED;
		}
		return op;
	}
}

OP *goto_cached_check(pTHX_ OP *o) {
	if ((o->op_type == OP_GOTO) && ((PL_hints & 0x220000) == 0x220000) && ((o->op_flags & OPf_SPECIAL) ^ OPf_SPECIAL)) {
		SV **svp = NULL;
		HV *table = GvHV(PL_hintgv);		
		if (table && (svp = hv_fetch(table, "Goto::Cached", 12, FALSE)) && *svp && SvOK(*svp)) {
			o->op_ppaddr = (o->op_flags & OPf_STACKED) ?
				goto_cached_dynamic :
				goto_cached_static;
		}
	}
    return o;
}

MODULE = Goto::Cached		PACKAGE = Goto::Cached		

PROTOTYPES: ENABLE

BOOT:
GOTO_CACHED_ALLOCATED_HASHES = newAV();
if (!GOTO_CACHED_ALLOCATED_HASHES) Perl_croak(aTHX_ "Can't create label hashes array");

SV *
addressof(labelsv, depth=0)
	SV *labelsv
	int depth
	PROTOTYPE: $;$
	PREINIT:
	OP *kid = Nullop;
	OP *o = Nullop;
    PERL_CONTEXT *cx;
	char *label = SvPVX(labelsv);
	CODE: 

	cx  = &cxstack[cxstack_ix - depth];
	/* Perl_warn("computing addressof %s", label); */
	switch (CxTYPE(cx)) {
		case CXt_EVAL:
			/* Perl_warn("context: eval"); */
			if (CxTRYBLOCK(cx)) {
				o = cx->blk_oldcop->op_sibling;
			} else {
				o = PL_eval_root;
			}
			break;
			/* else fall through */
		case CXt_LOOP:
			/* Perl_warn("context: loop"); */
			o = cx->blk_oldcop->op_sibling;
			if ((CxTYPE(cx) == CXt_LOOP) && (cLOOPx(cUNOPo->op_first)->op_redoop)) {
				/* Perl_warn("redoop: 0x%x", cLOOPx(cUNOPo->op_first)->op_redoop); */
				for (kid = cLOOPx(cUNOPo->op_first)->op_redoop; kid; kid = kid->op_sibling) {
					if ((kid->op_type == OP_NEXTSTATE || kid->op_type == OP_DBSTATE) &&
						kCOP->cop_label && strEQ(kCOP->cop_label, label)) {
						break;
					}
				}
			} else {
				/* Perl_warn("no redoop"); */
				/* Perl_op_dump(o); */
				o = cUNOPo->op_first->op_sibling;
				if (o->op_type != OP_LINESEQ) {
					Perl_croak(aTHX_ "invalid addressof context: can't find line sequence");
				}
			}

			break;
		case CXt_BLOCK:
			/* Perl_warn("context: block"); */
			if (cxstack_ix) {
				o = cx->blk_oldcop->op_sibling;
			} else {
				o = PL_main_root;
			}
			break;
		case CXt_SUB:
			/* Perl_warn("context: sub"); */
			if (CvDEPTH(cx->blk_sub.cv)) {
				o = CvROOT(cx->blk_sub.cv);
				break;
			}
			/* FALL THROUGH */
		default:
			/* Perl_warn("context: default"); */
			if (cxstack_ix) {
				Perl_croak(aTHX_ "invalid addressof context: 0x%x", CxTYPE(cx));
			} else {
				o = PL_main_root;
			}
	}

	if (!kid) {
		if (o->op_flags & OPf_KIDS) {
			if (cUNOPo->op_first->op_type == OP_LINESEQ)
				o = cUNOPo->op_first;

			for (kid = cUNOPo->op_first; kid; kid = kid->op_sibling) {
				if ((kid->op_type == OP_NEXTSTATE || kid->op_type == OP_DBSTATE) &&
					kCOP->cop_label && strEQ(kCOP->cop_label, label)) {
					break;
				}
			}
		} else {
			Perl_croak(aTHX_ "invalid addressof context: no kids");
		}
	}

	/* Perl_warn("returning address: 0x%x", kid); */
	RETVAL = kid ? newRV_noinc(newSVuv(PTR2UV(kid))) : &PL_sv_undef;
	OUTPUT:
		RETVAL

void
enterscope()
	PROTOTYPE:
	CODE: 
		/* Perl_warn(aTHX_ "inside enterscope\n"); */
		if (GOTO_CACHED_SCOPE_DEPTH > 0) {
			++GOTO_CACHED_SCOPE_DEPTH;
		} else {
			GOTO_CACHED_SCOPE_DEPTH = 1;
			PL_check[OP_GOTO] = goto_cached_check;
		}

void
leavescope()
	PROTOTYPE:
	CODE: 
		/* Perl_warn(aTHX_ "inside leavescope\n"); */
		if (GOTO_CACHED_SCOPE_DEPTH > 1) {
			--GOTO_CACHED_SCOPE_DEPTH;
		} else {
			GOTO_CACHED_SCOPE_DEPTH = 0;
			PL_check[OP_GOTO] = Perl_ck_null;
		}

void
END()
	PROTOTYPE:
	CODE: 
		/* Perl_warn(aTHX_ "inside END\n"); */
		GOTO_CACHED_SCOPE_DEPTH = 0;
		av_clear(GOTO_CACHED_ALLOCATED_HASHES);
		av_undef(GOTO_CACHED_ALLOCATED_HASHES);
