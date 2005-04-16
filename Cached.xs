#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ptable.h"

#define GOTO_LABEL_CACHE_STORE(key,len,val) \
STMT_START { \
    if (!hv_store(GOTO_LABEL_CACHE, key, len, newSViv((int)val), 0)) {\
		croak("Can't store value in goto cache"); \
    } \
} STMT_END

#define GOTO_LABEL_CACHE_FETCH(key,len) (hv_fetch(GOTO_LABEL_CACHE, key, len, 0))

OP* goto_cached(pTHX);
OP *goto_cached_ck_null(pTHX_ OP *o);

static HV *GOTO_LABEL_CACHE = NULL;
static PTABLE_t *GOTO_OP_CACHE = NULL;
static char * GOTO_KEY = NULL;
static size_t GOTO_KEYLEN = 256;
static U32 GOTO_CACHED_SCOPE_DEPTH = 0;

static OP *last_goto_src = NULL;
static OP *last_goto_dst = NULL;

OP* goto_cached(pTHX) {
	dSP;
	OP *op;

	if (PL_op->op_flags & OPf_STACKED) {
		SV *sv, **svp;
		size_t klen;

		/* Perl_warn(aTHX_ "\ndynamic goto\n"); */
		sv = TOPs;

		/* if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV) { */ /* goto &sub */
		if (SvROK(sv) || (PL_op->op_flags & OPf_SPECIAL)) { /* goto &sub or dump() */
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
			if (!PL_lastgotoprobe)
				GOTO_LABEL_CACHE_STORE(GOTO_KEY, klen, op);
		}

	} else { /* op has label hardwired - use ptable keyed on the op */
		/* Perl_warn(aTHX_ "\nstatic goto\n"); */
		if (PL_op == last_goto_src)
			RETURNOP(last_goto_dst);

		op = (OP *)PTABLE_fetch(GOTO_OP_CACHE, PL_op);

		if (op) {
			last_goto_src = PL_op;
			last_goto_dst = op;
		} else {
			/* Perl_warn(aTHX_ "computing op\n"); */
			op = Perl_pp_goto(aTHX);
			/* bypass the cache if the target is not in scope */
			if (!PL_lastgotoprobe)
				PTABLE_store(GOTO_OP_CACHE, PL_op, op);
		}
	}

	/* Perl_warn(aTHX_ "op: 0x%x\ntarget: 0x%x\nscope: 0x%x\n", PL_op, op, PL_lastgotoprobe); */
	RETURNOP(op);
}

OP *goto_cached_ck_null(pTHX_ OP *o) {
	if (o->op_type == OP_GOTO) {
		SV **svp = NULL;
		HV *table = GvHV(PL_hintgv);		
		if (table && (svp = hv_fetch(table, "Goto::Cached", 12, FALSE)) && *svp && SvOK(*svp)) {
			o->op_ppaddr = MEMBER_TO_FPTR(goto_cached);
		}
	}
    return o;
}

MODULE = Goto::Cached		PACKAGE = Goto::Cached		

PROTOTYPES: ENABLE

BOOT:
GOTO_LABEL_CACHE = newHV(); if (!GOTO_LABEL_CACHE) croak ("Can't initialize goto cache");
HvSHAREKEYS_off(GOTO_LABEL_CACHE); /* we don't need the speed hit of shared keys */
GOTO_OP_CACHE = PTABLE_new(); 
Newz(0, GOTO_KEY, GOTO_KEYLEN, char);

void
enterscope()
	PROTOTYPE:
	CODE: 
		if (GOTO_CACHED_SCOPE_DEPTH > 0) {
			++GOTO_CACHED_SCOPE_DEPTH;
		} else {
			GOTO_CACHED_SCOPE_DEPTH = 1;
			/* Perl_warn(aTHX_ "inside Goto::Cached::enterscope\n"); */
			PL_check[OP_GOTO] = MEMBER_TO_FPTR(goto_cached_ck_null);
		}

void
leavescope()
	PROTOTYPE:
	CODE: 
		if (GOTO_CACHED_SCOPE_DEPTH > 1) {
			--GOTO_CACHED_SCOPE_DEPTH;
		} else {
			GOTO_CACHED_SCOPE_DEPTH = 0;
			/* Perl_warn(aTHX_ "inside Goto::Cached::leavescope\n"); */
			PL_check[OP_GOTO] = MEMBER_TO_FPTR(Perl_ck_null);
		}

void
cleanup()
	PROTOTYPE:
	CODE: 
		/* Perl_warn(aTHX_ "inside Goto::Cached::cleanup\n"); */
		PTABLE_free(GOTO_OP_CACHE);
		GOTO_OP_CACHE = NULL;
		Safefree(GOTO_KEY);
		GOTO_CACHED_SCOPE_DEPTH = 0;
