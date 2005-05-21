#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define GOTO_CACHED_CACHED 128

OP* goto_cached_static(pTHX);
OP* goto_cached_dynamic(pTHX);
OP *goto_cached_check(pTHX_ OP *o);

static U32 GOTO_CACHED_SCOPE_DEPTH = 0;
static AV *GOTO_CACHED_ALLOCATED_HASHES = NULL;

OP* goto_cached_static(pTHX) {
	dSP;
	OP *op;

	if (PL_op->op_private & GOTO_CACHED_CACHED) {
		RETURNOP(PL_op->op_next);
	} else {
		op = Perl_pp_goto(aTHX);

		if (PL_lastgotoprobe) { /* target not in the current scope */
			PL_op->op_ppaddr = MEMBER_TO_FPTR(Perl_pp_goto);
		} else {
			PL_op->op_next = op;
			PL_op->op_private |= GOTO_CACHED_CACHED;
		}
		return op;
	}
}

OP* goto_cached_dynamic(pTHX) {
	dSP;
	SV *sv = TOPs;
	OP *op = NULL;
	size_t len;
	char *label = SvPV(sv, len);

	if (SvROK(sv)) {
		if (SvTYPE(SvRV(sv)) == SVt_IV) {
			RETURNOP((OP *)SvIVX(SvRV(sv)));
		} else {
			PL_op->op_private &= ~GOTO_CACHED_CACHED;
			PL_op->op_ppaddr = MEMBER_TO_FPTR(Perl_pp_goto);
			return Perl_pp_goto(aTHX);
		}
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
			PL_op->op_next = (char *)hv;
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
				MEMBER_TO_FPTR(goto_cached_dynamic) :
				MEMBER_TO_FPTR(goto_cached_static);
		}
	}
    return o;
}

MODULE = Goto::Cached		PACKAGE = Goto::Cached		

PROTOTYPES: ENABLE

BOOT:
GOTO_CACHED_ALLOCATED_HASHES = newAV();
if (!GOTO_CACHED_ALLOCATED_HASHES) Perl_croak(aTHX_ "Can't create label hashes array");

void
enterscope()
	PROTOTYPE:
	CODE: 
		if (GOTO_CACHED_SCOPE_DEPTH > 0) {
			++GOTO_CACHED_SCOPE_DEPTH;
		} else {
			GOTO_CACHED_SCOPE_DEPTH = 1;
			PL_check[OP_GOTO] = MEMBER_TO_FPTR(goto_cached_check);
		}

void
leavescope()
	PROTOTYPE:
	CODE: 
		if (GOTO_CACHED_SCOPE_DEPTH > 1) {
			--GOTO_CACHED_SCOPE_DEPTH;
		} else {
			GOTO_CACHED_SCOPE_DEPTH = 0;
			PL_check[OP_GOTO] = MEMBER_TO_FPTR(Perl_ck_null);
		}

void
END()
	PROTOTYPE:
	CODE: 
		GOTO_CACHED_SCOPE_DEPTH = 0;
		av_clear(GOTO_CACHED_ALLOCATED_HASHES);
		av_undef(GOTO_CACHED_ALLOCATED_HASHES);
