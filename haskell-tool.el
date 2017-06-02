;;; haskell-tool.el --- This file contains configuration and routines for working with various haskell tools -*- lexical-binding: t -*-

;;; Commentary:

;;; This file provides structures representing different haskell tool
;;; configurations.

;; Copyright © 2014 Chris Done.  All rights reserved.
;;             2017 Chris Sasarak

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'haskell-customize)
(require 'haskell-session)

;; Utility Functions

(defun haskell-tool-path-to-list (path)
  "Convert a path (which may be a string or a list) to a list."
  (if (stringp path)
      (list path)
    path))

;; Configuration structure and tool configurations

(cl-defstruct haskell-tool-config
  "This structure is used to represent all the information haskell-mode
   needs about a particular tool (e.g. stack, cabal, etc) in order to
   use it.

   'tool-name' is the name of the tool used by this structure, it should
    be appropriate for printing to users.

   'is-usablep' is a function which when called will say whether or not
   this tool can be used in the current environment/project.

   'process-path' is a string which is the path this tool with use to
   start a process.

   'compute-process-log-and-command' computes the log and process to
   start a command for a given SESSION for this tool.
   "
  tool-name
  (is-usablep (lambda () nil))
  (process-path "")
  (compute-process-log-and-command (lambda () nil)))

(defvar haskell-mode-auto
  (make-haskell-tool-config)
  "Ideally, auto should be a sane default.")

(defvar haskell-mode-stack-ghci
  (make-haskell-tool-config
   :tool-name "stack"
   :is-usablep (lambda ()
                 (and (locate-dominating-file default-directory "stack.yaml")
                      (executable-find "stack")))
   :process-path haskell-process-path-stack
   :compute-process-log-and-command (lambda (session)
                                      (let ((session-name (haskell-session-name session)))
                                        (append (list (format "Starting inferior %s GHCi process using %s"
                                                              (haskell-tool-config-tool-name haskell-mode-stack-ghci)
                                                              (haskell-tool-config-process-path haskell-mode-stack-ghci))
                                                      session-name
                                                      nil)
                                                (apply haskell-process-wrapper-function
                                                       (list
                                                        (append
                                                         (haskell-tool-path-to-list haskell-process-path-stack)
                                                         (list "ghci")
                                                         (let ((target (haskell-session-target session)))
                                                           (if target (list target) nil))
                                                         haskell-process-args-stack-ghci)))))))
  "Tool functions and data for using stack-ghci.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Accessor functions

;; TODO: Eventually return one of the haskell-tool-configuration structures
(defun haskell-process-type ()
  "Return `haskell-process-type', or a guess if that variable is 'auto."
  (if (eq 'auto haskell-process-type)
      (cond
       ;; User has explicitly initialized this project with cabal
       ((locate-dominating-file default-directory "cabal.sandbox.config")
        'cabal-repl)
       ((funcall (haskell-tool-config-is-usablep haskell-mode-stack-ghci))
        'stack-ghci)
       ((locate-dominating-file
         default-directory
         (lambda (d)
           (cl-find-if (lambda (f) (string-match-p ".\\.cabal\\'" f)) (directory-files d))))
        'cabal-repl)
       (t 'ghci))
    haskell-process-type))

(provide 'haskell-tool)
;;; haskell-tool.el ends here
