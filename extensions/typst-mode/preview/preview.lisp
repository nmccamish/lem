(uiop:define-package :lem-typst-mode/preview/preview
  (:use :cl :lem)
  (:export :typst-preview
           :typst-preview-stop
           :typst-set-preview-root))
(in-package :lem-typst-mode/preview/preview)



(defstruct typst-preview-session
  process
  url
  filepath)

(defvar *typst-preview-sessions* (make-hash-table :test 'equal))
(defvar *typst-root* "")


(defun stop-preview-process (filepath)
  "Stop the active preview process for FILEPATH if it exists."
  (let ((session (gethash filepath *typst-preview-sessions*)))
    (when session
      (let ((proc (typst-preview-session-process session)))
        (when (and proc (uiop:process-alive-p proc))
          (ignore-errors (uiop:terminate-process proc :urgent t))))
      (remhash filepath *typst-preview-sessions*))))


(define-command typst-set-preview-root () ()
  (let ((dir (prompt-for-directory "Typst preview root: "
                                   :directory (buffer-directory))))
    (when dir
      (setf *typst-root* (namestring dir))
      (message "Typst root directory set to : ~A" *typst-root*))))

(define-command typst-export-file (output-pdf)
    ((prompt-for-string "PDF Name : " :initial-value (concatenate 'string (namestring (buffer-directory)) "out.pdf")))
  (let* ((input (buffer-filename (current-buffer)))
        (cmd (append (list "typst" "compile" (namestring input))  
                     (when (and *typst-root* (not (string= *typst-root* "")))
                       (list "--root" *typst-root*))
                     (list output-pdf))))
        (uiop:run-program cmd))
    (message "Exported successfully in ~A" output-pdf))
                        

(defun typst-cleanup-tinymist ()
  "Kill active tinymist before closing lem"
  (maphash (lambda (filepath session)
             (declare (ignore filepath))
             (let ((process (typst-preview-session-process session)))
               (when (and process (uiop:process-alive-p process))
                 (ignore-errors (uiop:terminate-process process :urgent t)))))
           *typst-preview-sessions*)
  (clrhash *typst-preview-sessions*))



;; clean all tinymist process in case editor is closed
(add-hook *exit-editor-hook* 'typst-cleanup-tinymist)

#+sbcl
(pushnew 'typst-cleanup-tinymist sb-ext:*exit-hooks*)

(define-command typst-preview () ()
  "Preview the current Typst buffer in the browser.
If the preview server is already running, reopens the URL in the browser without restarting.
Otherwise, starts a new tinymist preview server.
We avoid relaunching tinymist by saving the url it uses for the preview."
  (let ((file (buffer-filename (current-buffer))))
    (if file
        (let* ((filepath (namestring file))Ʉ
                                           (session (gethash filepath *typst-preview-sessions*)))
          (cond
            ;; Server is already running: reopen the browser at the existing URL without restarting
            
            ((and session
                 (typst-preview-session-process session)
                 (uiop:process-alive-p (typst-preview-session-process session)))
            (let ((url (or (typst-preview-session-url session) "http://127.0.0.1:23625")))
              (lem:open-external-file url)
              (message "Reopened Typst preview at ~A" url)))
            ;; Server is not running: start a new tinymist preview instance
            (t
             (stop-preview-process filepath)
             (let* ((cmd (append (list "tinymist" "preview")
                                 (when (and *typst-root* (not (string= *typst-root* "")))
                                   (list "--root" *typst-root*))
                                 (list "--open" filepath)))
                    (proc (uiop:launch-program cmd))
                    (url "http://127.0.0.1:23625")) ;; Maybe make this a variable so user can customise ?
               (setf (gethash filepath *typst-preview-sessions*)
                     (make-typst-preview-session :process proc
                                                 :url url
                                                 :filepath filepath))
               (message "Started Typst preview for ~A" (file-namestring filepath))))))
        (editor-error "Current buffer is not associated with a saved file."))))

(define-command typst-preview-stop () ()
  "Stop the Typst preview server for the current buffer."
  (let ((file (buffer-filename (current-buffer))))
    (if file
        (let ((filepath (namestring file)))
          (if (gethash filepath *typst-preview-sessions*)
              (progn
                (stop-preview-process filepath)
                (message "Typst preview server stopped."))
              (message "No active preview server for this file. ~A" filepath)))
        (editor-error "Current buffer is not associated with a file."))))