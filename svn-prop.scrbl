#lang scribble/manual
@(require (for-label scheme/base
                     scheme/gui
                     scheme/contract
                     "main.ss"))

@title{SVN Properties}
@author{@(author+email "Jay McCarthy" "jay@plt-scheme.org")}

A small FFI for Subversion working copy properties

@defmodule[(planet jaymccarthy/svn-prop)]

@defproc[(svn-property-value [wc-path string?] [prop-name string])
         (or/c false/c string?)]

Returns the value of the @scheme[prop-name] property of the Subversion working copy path @scheme[wc-path]. If @scheme[wc-path] is not a Subversion working copy @emph{or} if it is but does not have a @scheme[prop-name] property, then @scheme[#f] is returned.