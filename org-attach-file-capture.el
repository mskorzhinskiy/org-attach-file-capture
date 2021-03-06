;;; org-attach-file.el --- capture and attach files to org-mode -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Mikhail Skorzhisnkii
;;
;; Author: Mikhail Skorzhisnkii <http://github/rasmi>
;; Maintainer: Mikhail Skorzhisnkii <mskorzhinskiy@eml.cc>
;; Created: January 05, 2021
;; Modified: January 05, 2021
;; Version: 0.0.1
;; Keywords:
;; Homepage: https://github.com/rasmi/org-attach-file
;; Package-Requires: ((emacs 27.1) (cl-lib "0.5"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  description
;;
;;; Code:

(require 'org)
(require 'org-capture)
(require 'org-attach)

(defcustom org-file-capture-templates org-capture-templates
  "Separate copy of capture templates for `org-attach-files-capture'."
  :group 'org-capture
  :set (lambda (s v) (set s (org-capture-upgrade-templates v)))
  :type
  (let ((file-variants '(choice :tag "Filename       "
                                (file :tag "Literal")
                                (function :tag "Function")
                                (variable :tag "Variable")
                                (sexp :tag "Form"))))
    `(repeat
      (choice :value ("" "" entry (file "~/org/notes.org") "")
              (list :tag "Multikey description"
                    (string :tag "Keys       ")
                    (string :tag "Description"))
              (list :tag "Template entry"
                    (string :tag "Keys           ")
                    (string :tag "Description    ")
                    (choice :tag "Capture Type   " :value entry
                            (const :tag "Org entry" entry)
                            (const :tag "Plain list item" item)
                            (const :tag "Checkbox item" checkitem)
                            (const :tag "Plain text" plain)
                            (const :tag "Table line" table-line))
                    (choice :tag "Target location"
                            (list :tag "File"
                                  (const :format "" file)
                                  ,file-variants)
                            (list :tag "ID"
                                  (const :format "" id)
                                  (string :tag "  ID"))
                            (list :tag "File & Headline"
                                  (const :format "" file+headline)
                                  ,file-variants
                                  (string :tag "  Headline"))
                            (list :tag "File & Outline path"
                                  (const :format "" file+olp)
                                  ,file-variants
                                  (repeat :tag "Outline path" :inline t
                                          (string :tag "Headline")))
                            (list :tag "File & Regexp"
                                  (const :format "" file+regexp)
                                  ,file-variants
                                  (regexp :tag "  Regexp"))
                            (list :tag "File [ & Outline path ] & Date tree"
                                  (const :format "" file+olp+datetree)
                                  ,file-variants
                                  (option (repeat :tag "Outline path" :inline t
                                                  (string :tag "Headline"))))
                            (list :tag "File & function"
                                  (const :format "" file+function)
                                  ,file-variants
                                  (sexp :tag "  Function"))
                            (list :tag "Current clocking task"
                                  (const :format "" clock))
                            (list :tag "Function"
                                  (const :format "" function)
                                  (sexp :tag "  Function")))
                    (choice :tag "Template       "
                            (string)
                            (list :tag "File"
                                  (const :format "" file)
                                  (file :tag "Template file"))
                            (list :tag "Function"
                                  (const :format "" function)
                                  (function :tag "Template function")))
                    (plist :inline t
                           ;; Give the most common options as checkboxes
                           :options (((const :format "%v " :prepend) (const t))
                                     ((const :format "%v " :immediate-finish) (const t))
                                     ((const :format "%v " :jump-to-captured) (const t))
                                     ((const :format "%v " :empty-lines) (const 1))
                                     ((const :format "%v " :empty-lines-before) (const 1))
                                     ((const :format "%v " :empty-lines-after) (const 1))
                                     ((const :format "%v " :clock-in) (const t))
                                     ((const :format "%v " :clock-keep) (const t))
                                     ((const :format "%v " :clock-resume) (const t))
                                     ((const :format "%v " :time-prompt) (const t))
                                     ((const :format "%v " :tree-type) (const week))
                                     ((const :format "%v " :unnarrowed) (const t))
				     ((const :format "%v " :table-line-pos) (string))
				     ((const :format "%v " :kill-buffer) (const t)))))))))

;;;###autoload
(defun org-attach-files-capture (files)
  "Move FILES at my file system to annex/org file storage."
    (save-excursion
      (let ((org-capture-templates org-file-capture-templates))
        (org-capture))
      ;; Create as many new headings as it need to be created
      (when (> (length files) 1)
        (save-excursion
          (org-clone-subtree-with-time-shift (- (length files) 1) '(4))))
      ;; Edit these headings and attach files to them
      (dolist (file files)
        (when (file-exists-p file)
          ;; Just some sane name should be enough
          (org-edit-headline (concat "File: " (file-name-nondirectory file)))
          ;; Attach file to the storage room
          (org-attach-attach file nil 'mv)
          ;; Edit headline once again with the stored file
          (let* ((attach-dir (org-attach-dir))
                 (files (org-attach-file-list attach-dir))
                 (file (pop files)))
            (org-edit-headline
             (format "[[attachment:%s][%s]]" file (org-get-heading t t t t))))
          ;; Go to the next free heading
          (org-next-visible-heading 1)))
      ;; Make sure that we didn't cancel capture with file that was already moved
      (org-capture-finalize)
      ;; Go to the file if we want to say something about it
      (org-capture-goto-last-stored)
      ;; Save buffer just in case
      (save-buffer)))

(provide 'org-attach-file-capture)
;;; org-attach-file-capture.el ends here
