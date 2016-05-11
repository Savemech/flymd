;;; flymd.el --- flymd   -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2016 Mola-T
;; Author: Mola-T <Mola@molamola.xyz>
;; URL: https://github.com/mola-T/flymd
;; Version: 1.0.0
;; Package-Requires: ()
;; Keywords:
;;
;;; License:
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;;; Commentary:
;; 
;;
;;; code:
(defgroup flymd nil
  "Group for flymd"
  :group 'markdown
  :group 'convenience)

(defcustom flymd-refresh-interval 0.5
  "Time to refresh the README."
  :group 'flymd)

(defcustom flymd-markdown-file-type
  '("\\.md\\'" "\\.markdown\\'")
  "Regexp to match markdown file."
  :group 'flymd
  :type '(repeat string))

(defcustom flymd-browser-open-function nil
  "Function used to open the browser.
It needs to accept one string argument which is the url.
If it is not defined, `browse-url-default-browser' is used."
  :group 'flymd
  :type 'function)

(defcustom flymd-browser-open-arg nil
  "If you use chrome, it needs to set to \"--allow-file-access-from-files\"."
  :group 'flymd
  :type 'string)

(defvar flymd-markdown-regex nil
  "A concatenated verion of `flymd-markdown-file-type'.")

(defconst flymd-preview-html-filename "flymd.html"
  "File name for flymd html.")

(defconst flymd-preview-md-filename "flymd.md"
  "File name for flymd md.")

(defconst flymd-point-identifier "fLyMd-mAkEr"
  "Insert this at point to help auto scroll.")

(defvar flymd-timer nil
  "Store the flymd timer.")

(defvar flymd-markdown-buffer-list nil
  "Store the markdown which has been flyit.")

;;;###autoload
(defun flymd-flyit ()
  "Enable realtime markdown preview on the current buffer."
  (interactive)
  (unless flymd-markdown-regex
    (setq flymd-markdown-regex (mapconcat 'identity flymd-markdown-file-type "\\|")))
  (if (string-match-p flymd-markdown-regex (buffer-file-name))
      (let ((working-buffer (current-buffer))
            (working-point (point)))
        (flymd-copy-html (file-name-directory (buffer-file-name working-buffer)))
        (flymd-generate-readme working-buffer working-point)
        (flymd-open-browser working-buffer)
        (unless flymd-timer
          (setq flymd-timer (run-with-idle-timer flymd-refresh-interval t 'flymd-generate-readme)))
        (cl-pushnew working-buffer flymd-markdown-buffer-list :test 'eq)
        (add-hook 'kill-buffer-hook #'flymd-unflyit t))
    (message "What's wrong with you???!\nDon't flyit if you are not viewing a markdown file.")))

(defun flymd-copy-html (dir)
  "Copy flymd.html to working directory DIR if it is no present."
  (unless (file-exists-p (concat dir flymd-preview-html-filename))
    (copy-file (concat (file-name-directory (locate-library "flymd")) flymd-preview-html-filename)
          dir)
    (unless (file-exists-p (concat dir flymd-preview-html-filename))
      (error "Opps! Cannot copy %s to working directory" flymd-preview-html-filename))))

(defun flymd-generate-readme (&optional buffer point)
  "Save working markdown file from BUFFER to flymd.md and add identifier to POINT."
  (when (or buffer (memq (current-buffer) flymd-markdown-buffer-list))
    (setq buffer (or buffer (current-buffer)))
    (setq point (or point (point)))
    (with-temp-buffer
      (insert-buffer-substring-no-properties buffer)
      (goto-char point)
      (when (string-match-p "\\````" (thing-at-point 'line t))
        (forward-line))
      (end-of-line)
      (insert flymd-point-identifier)
      (write-region (point-min)
                    (point-max)
                    (concat (file-name-directory (buffer-file-name buffer)) flymd-preview-md-filename)
                    nil
                    'hey-why-are-you-inspecting-my-source-code?))))

(defun flymd-open-browser (&optional buffer)
  "Open the browser with the flymd.html if BUFFER succeeded converting to flymd.md."
  (if (file-readable-p (concat (file-name-directory (buffer-file-name buffer)) flymd-preview-md-filename))
      (if flymd-browser-open-function
          (funcall flymd-browser-open-function
                   (concat (file-name-directory (buffer-file-name buffer)) flymd-preview-html-filename))
        (browse-url (concat (file-name-directory (buffer-file-name buffer)) flymd-preview-html-filename)
                    flymd-browser-open-arg))
    (error "Opps! flymd cannot create preview markdown flymd.md")))

(defun flymd-unflyit ()
  "Untrack a markdown buffer in `flymd-markdown-buffer-list'."
  (setq flymd-markdown-buffer-list (remq (current-buffer) flymd-markdown-buffer-list))
  (unless flymd-markdown-buffer-list
    (ignore-errors (cancel-timer flymd-timer))
    (setq flymd-timer nil)))

(provide 'flymd)
;;; flymd.el ends here