;;; anything-{anything-template-name}.el --- Quick listing of:

;; This file is not part of Emacs

;; Copyright (C) 2011 Jose Pablo Barrantes
;; Created: 18/Dec/11
;; Version: 0.1.0

;;; Installation:

;; Put this file where you defined your `load-path` directory or just
;; add the following line to your emacs config file:

;; (load-file "/path/to/anything-{anything-template-name}.el")

;; Finally require it:

;; (require 'anything-{anything-template-name})

;; Usage:
;; M-x anything-{anything-template-name}

;; There is no need to setup load-path with add-to-list if you copy
;; `anything-{anything-template-name}.el` to load-path directories.

;; Requirements:

;; http://www.emacswiki.org/emacs/Anything

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'anything)

;;; --------------------------------------------------------------------
;;; - Customization
;;;
(defvar *buffer-name*
  "*Anything {anything-template-name}*")

(defvar  {anything-template-name}-cmd "")

(defun anything--{anything-template-name}-action (candidate)
  (setq args
        (read-from-minibuffer
         (concat "Run cmd as such: " candidate)))
  (compilation-start
   (concat candidate args) nil
   (lambda (x)
     (concat "*Anything {anything-template-name}: " candidate " " args "*"))))

(defvar anything-c-source-{anything-template-name}
   '((name . "Anything {anything-template-name}")
     (init
      . (lambda ()
          (call-process-shell-command anything-{anything-template-name}-cmd
                                      nil (anything-candidate-buffer 'global))))
    (candidate-number-limit . 9999)
    (candidates-in-buffer)
    (action . anything-{anything-template-name}-action))
   "Find: .")

;;;###autoload
(defun anything-{anything-template-name} ()
  "Find: ."
  (interactive)
  (setq buff-name
        (concat "*Anything {anything-template-name}: " default-directory " *"))
  (anything-other-buffer
   '(anything-c-source-{anything-template-name})
   buff-name))

(provide 'anything-{anything-template-name})
