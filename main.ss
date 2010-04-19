#lang scheme
(require scheme/foreign
         (prefix-in c: scheme/contract)
         (planet murphy/svn/apr)
         (planet murphy/svn/subr))

(unsafe!)
(unsafe-subr!)

(define libapr (ffi-lib "libapr-1"))
(define libsvn_client (ffi-lib "libsvn_client-1"))
(define libsvn_wc (ffi-lib "libsvn_wc-1"))

(define-syntax-rule (define-ffi lib sym typ)
  (define sym (get-ffi-obj 'sym lib typ)))

(define-cpointer-type _svn_client_ctx _pooled-pointer)

(define-ffi libsvn_client svn_client_create_context
  (_fun (ctx : (_ptr o _svn_client_ctx))
        (pool : _pool)
        -> [err : _error/null]
        -> (begin (check-error 'svn_client_create_context err)
                  ctx)))

(define _svn_opt_revision_kind
  (_enum '(svn_opt_revision_unspecified
           svn_opt_revision_number
           svn_opt_revision_date
           svn_opt_revision_committed
           svn_opt_revision_previous
           svn_opt_revision_base
           svn_opt_revision_working
           svn_opt_revision_head)))

(define _svn_opt_revision_value _int) ; XXX actually a union of other stuff, but I don't use them in this library

(define-cstruct
  _svn_opt_revision
  ([kind _svn_opt_revision_kind]
   [extra _svn_opt_revision_value]))

(define svn_depth_empty 0) ; 323 of svn_types

#|
svn_error_t* svn_client_propget2	(
 	apr_hash_t ** 	props,
 	const char * 	propname,
 	const char * 	target,
 	const svn_opt_revision_t * 	peg_revision,
 	const svn_opt_revision_t * 	revision,
 	svn_boolean_t 	recurse,
 	svn_client_ctx_t * 	ctx,
 	apr_pool_t * 	pool
) 	|#
(define _svn_boolean _bool)
(define-ffi libsvn_client svn_client_propget2
  (_fun [props : (_ptr o _apr-hash)]
        [prop-name : _string]
        [target : _path]
        [peg-rev : _svn_opt_revision-pointer]
        [rev : _svn_opt_revision-pointer]
        [recurse : _svn_boolean]
        [ctx : _svn_client_ctx]
        [pool : _pool]
        -> [err : _error/null]
        -> (begin (check-error 'svn_client_propget3 err)
                  props)))

(define-ffi libapr apr_hash_get
  (_fun _apr-hash
        [s : _string]
        [len : _int = (string-length s)]
        -> _svn-string-pointer/null))

(define (svn-property-value wc-path prop-name)
  (define the-pool (make-pool))
  (define ctx (svn_client_create_context the-pool))
  (define rev (make-svn_opt_revision 'svn_opt_revision_working 0))
  (define props
    (svn_client_propget2 prop-name
                         wc-path
                         rev rev
                         #f
                         ctx
                         the-pool))
  (define res
   (svn-string->bytes (apr_hash_get props wc-path)))
  (and res
       (bytes->string/utf-8 res)))

(provide/contract
 [svn-property-value (string? string? . c:-> . (or/c false/c string?))])