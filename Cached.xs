#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define GOTO_LABEL_CACHE_STORE(key,len,val) \
STMT_START { \
    if (!hv_store(GOTO_LABEL_CACHE, key, len, newSViv((int)val), 0)) {\
		croak("Can't store value in goto cache"); \
    } \
} STMT_END

#define GOTO_LABEL_CACHE_FETCH(key,len) (hv_fetch(GOTO_LABEL_CACHE, key, len, 0))

OP* goto_cached_static(pTHX);
OP* goto_cached_dynamic(pTHX);
OP *goto_cached_check(pTHX_ OP *o);

static HV *GOTO_LABEL_CACHE = NULL;
static char * GOTO_KEY = NULL;
static size_t GOTO_KEYLEN = 256;
static U32 GOTO_CACHED_SCOPE_DEPTH = 0;

#define GOTO_CACHED_CACHED 1

OP* goto_cached_static(pTHX) {
	dSP;
	OP *op;

	/* Perl_warn(aTHX_ "\nstatic goto\n"); */

	if (PL_op->op_private & GOTO_CACHED_CACHED) {
		RETURNOP(PL_op->op_next);
	} else {
		op = Perl_pp_goto(aTHX);

		if (PL_lastgotoprobe) { /* target not in the current scope */
			op->op_ppaddr = MEMBER_TO_FPTR(Perl_pp_goto);
			return Perl_pp_goto(aTHX);
		} else {
			PL_op->op_next = op;
			PL_op->op_private |= GOTO_CACHED_CACHED;
		}
	}
	RETURNOP(op);
}

OP* goto_cached_dynamic(pTHX) {
	dSP;
	OP *op;
	size_t klen;
	SV **svp, *sv = TOPs;
	/* U8 flags = PL_op->op_private; */

	/* Perl_warn(aTHX_ "\ndynamic goto\n"); */

	/* if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV) */ /* goto &sub */
	/* if (SvROK(sv) || (flags & OPf_SPECIAL)) */ /* goto &sub or dump() */
	if (SvROK(sv)) {
		/* Perl_warn(aTHX_ "goto &sub\n"); */
		return Perl_pp_goto(aTHX);
	} else {
		/* Perl_warn(aTHX_ "goto $label\n"); */
		klen = UVSIZE * 2 + 1 + SvCUR(sv);
		if (klen > GOTO_KEYLEN) {
			while (klen > GOTO_KEYLEN) {
				GOTO_KEYLEN = GOTO_KEYLEN * 2;
			}
			Renew(GOTO_KEY, GOTO_KEYLEN, char);
		}
		snprintf(GOTO_KEY, klen, "%0*"UVxf"%s", UVSIZE * 2, PTR2UV(PL_op), SvPVX(sv));
	}

	/* Perl_warn(aTHX_ "key: %s\n", GOTO_KEY); */
	svp = GOTO_LABEL_CACHE_FETCH(GOTO_KEY, klen);

	if (svp) {
		/* Perl_warn(aTHX_ "found op\n"); */
		op = INT2PTR(OP *, SvIVX(*svp));
	} else {
		/* Perl_warn(aTHX_ "computing op\n"); */
		op = Perl_pp_goto(aTHX);
		/* bypass the cache if the target is not in scope */
		if (!PL_lastgotoprobe) {
			GOTO_LABEL_CACHE_STORE(GOTO_KEY, klen, op);
		} else {
			Perl_warn(aTHX_ "label out of range");
		}
	}

	/* Perl_warn(aTHX_ "op: 0x%x\ntarget: 0x%x\nscope: 0x%x\n", PL_op, op, PL_lastgotoprobe); */
	RETURNOP(op);
}

OP *goto_cached_check(pTHX_ OP *o) {
	/* Perl_warn(aTHX_ "inside goto_cached_check: 0x%x", PL_hints); */
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
GOTO_LABEL_CACHE = newHV(); if (!GOTO_LABEL_CACHE) croak ("Can't initialize goto cache");
HvSHAREKEYS_off(GOTO_LABEL_CACHE); /* we don't need the speed hit of shared keys */
Newz(0, GOTO_KEY, GOTO_KEYLEN, char);

void
enterscope()
	PROTOTYPE:
	CODE: 
		if (GOTO_CACHED_SCOPE_DEPTH > 0) {
			++GOTO_CACHED_SCOPE_DEPTH;
		} else {
			GOTO_CACHED_SCOPE_DEPTH = 1;
			/* Perl_warn(aTHX_ "inside Goto::Cached::enterscope: 0x%x\n", PL_hints); */
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
			/* Perl_warn(aTHX_ "inside Goto::Cached::leavescope: 0x%x\n", PL_hints); */
			PL_check[OP_GOTO] = MEMBER_TO_FPTR(Perl_ck_null);
		}

void
cleanup()
	PROTOTYPE:
	CODE: 
		/* Perl_warn(aTHX_ "inside Goto::Cached::cleanup\n"); */
		Safefree(GOTO_KEY);
		GOTO_CACHED_SCOPE_DEPTH = 0;
