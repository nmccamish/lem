(uiop:define-package :lem-typst-mode/preview/preview
  (:use :cl :lem))
(in-package :lem-typst-mode/preview/preview)


(define-command typst-preview () ()
  "Preview the current typst buffer as a pdf"
  (uiop:run-program '("tinymist" "preview"  (current-buffer)) ))