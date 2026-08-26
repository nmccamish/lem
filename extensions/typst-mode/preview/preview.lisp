(uiop:define-package :lem-typst-mode/preview/preview
  (:use :cl :lem)
  (:export :typst-preview
           :typst-preview-stop))
(in-package :lem-typst-mode/preview/preview)

(defstruct preview-session
  process
  url
  filepath)

(defvar *preview-sessions* (make-hash-table :test 'equal))

(defun stop-preview-process (filepath)
  "Stop the active preview process for FILEPATH if it exists."
  (let ((session (gethash filepath *preview-sessions*)))
    (when session
      (let ((proc (preview-session-process session)))
        (when (and proc (uiop:process-alive-p proc))
          (ignore-errors (uiop:terminate-process proc :urgent t))))
      (remhash filepath *preview-sessions*))))

(define-command typst-preview () ()
  "Preview the current Typst buffer in the browser.
If the preview server is already running, reopens the URL in the browser without restarting.
Otherwise, starts a new tinymist preview server."
  (let ((file (buffer-filename (current-buffer))))
    (if file
        (let* ((filepath (namestring file))
               (session (gethash filepath *preview-sessions*)))
          (cond
            ;; Server is already running: reopen the browser at the existing URL without restarting
            ((and session
                  (preview-session-process session)
                  (uiop:process-alive-p (preview-session-process session)))
             (let ((url (or (preview-session-url session) "http://127.0.0.1:23625")))
               (lem:open-external-file url)
               (message "Reopened Typst preview at ~A" url)))
            ;; Server is not running: start a new tinymist preview instance
            (t
             (stop-preview-process filepath)
             (let* ((proc (uiop:launch-program (list "tinymist" "preview" "--open" filepath)))
                    (url "http://127.0.0.1:23625"))
               (setf (gethash filepath *preview-sessions*)
                     (make-preview-session :process proc
                                           :url url
                                           :filepath filepath))
               (message "Started Typst preview for ~A" (file-namestring filepath))))))
        (editor-error "Current buffer is not associated with a saved file."))))

(define-command typst-preview-stop () ()
  "Stop the Typst preview server for the current buffer."
  (let ((file (buffer-filename (current-buffer))))
    (if file
        (let ((filepath (namestring file)))
          (if (gethash filepath *preview-sessions*)
              (progn
                (stop-preview-process filepath)
                (message "Typst preview server stopped."))
              (message "No active preview server for this file.")))
        (editor-error "Current buffer is not associated with a file."))))