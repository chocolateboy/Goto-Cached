#define PERL_CORE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

OP * goto_cached_static(pTHX);
OP * goto_cached_dynamic(pTHX);
OP * goto_cached_check(pTHX_ OP *o);
OP * goto_cached_static_cached(pTHX);

static OP * (*old_ck_goto)(pTHX_ OP * op) = NULL;
static U32 SCOPE_DEPTH = 0;
static AV * GOTO_CACHED_ALLOCATED_HASHES = NULL;
static U8 GOTO_CACHED_CACHED = 128;

OP* goto_cached_static_cached(pTHX) {
    return (PL_op->op_next);
}

OP* goto_cached_static(pTHX) {
    OP * op;
    op = PL_ppaddr[OP_GOTO](aTHXR);

    if (PL_lastgotoprobe) { /* target is not in scope */
        PL_op->op_ppaddr = PL_ppaddr[OP_GOTO];
    } else {
        PL_op->op_next = op;
        PL_op->op_ppaddr = goto_cached_static_cached;
    }

    return op;
}

OP* goto_cached_dynamic(pTHX) {
    dSP;
    SV * sv = TOPs;
    OP * op = NULL;
    STRLEN len;
    char * label = SvPV(sv, len);

    if (SvROK(sv)) {
        PL_op->op_private &= ~GOTO_CACHED_CACHED;
        PL_op->op_ppaddr = PL_ppaddr[OP_GOTO];
        return PL_ppaddr[OP_GOTO](aTHXR);
    } else if (PL_op->op_private & GOTO_CACHED_CACHED) {
        SV ** svp;

        svp = hv_fetch((HV *)PL_op->op_next, label, len, 0);

        if (svp && *svp && SvOK(*svp)) {
            RETURNOP(INT2PTR(OP *, SvIVX(*svp)));
        } else {
            op = PL_ppaddr[OP_GOTO](aTHXR);
            if (PL_lastgotoprobe) { /* target is not in scope */
                PL_op->op_private &= ~GOTO_CACHED_CACHED;
                PL_op->op_ppaddr = PL_ppaddr[OP_GOTO];
            } else {
                (void)hv_store((HV *)PL_op->op_next, label, len, newSVuv(PTR2UV(op)), 0);
            }
            return op;
        }
    } else {
        op = PL_ppaddr[OP_GOTO](aTHXR);
        if (PL_lastgotoprobe) { /* target is not in scope */
            PL_op->op_ppaddr = PL_ppaddr[OP_GOTO];
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
    if ((o->op_type == OP_GOTO) && (PL_hints & 0x020000)) {
        SV ** svp;
        HV * table = GvHV(PL_hintgv);

        if (table && (svp = hv_fetch(table, "Goto::Cached", 12, FALSE)) && *svp && SvOK(*svp)) {
            o->op_ppaddr = (o->op_flags & OPf_STACKED) ?
                goto_cached_dynamic :
                goto_cached_static;
        }
    }

    return CALL_FPTR(old_ck_goto)(aTHX_ o);
}

MODULE = Goto::Cached                PACKAGE = Goto::Cached                

PROTOTYPES: ENABLE

BOOT:
GOTO_CACHED_ALLOCATED_HASHES = newAV();
if (!GOTO_CACHED_ALLOCATED_HASHES) Perl_croak(aTHX_ "Can't create label hashes array");

void
_enter()
    PROTOTYPE:
    CODE: 
    if (SCOPE_DEPTH > 0) {
        ++SCOPE_DEPTH;
    } else {
        SCOPE_DEPTH = 1;
        /*
         * capture the check routine in scope when Goto::Cached is used.
         * usually, this will be Perl_ck_null, though, in principle,
         * it could be a bespoke checker spliced in by another module.
         */
        old_ck_goto = PL_check[OP_GOTO];
        PL_check[OP_GOTO] = goto_cached_check;
    }

void
_leave()
    PROTOTYPE:
    CODE: 
    if (SCOPE_DEPTH == 0) {
        Perl_warn(aTHX_ "scope underflow");
    }

    if (SCOPE_DEPTH > 1) {
        --SCOPE_DEPTH;
    } else {
        SCOPE_DEPTH = 0;
        PL_check[OP_GOTO] = old_ck_goto;
    }

void
END()
    PROTOTYPE:
    CODE: 
        av_clear(GOTO_CACHED_ALLOCATED_HASHES);
        av_undef(GOTO_CACHED_ALLOCATED_HASHES);
