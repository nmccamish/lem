(defsystem "lem-typst-mode"
  :depends-on ("lem/core"
               "lem-lsp-mode"
               "lem-tree-sitter"
               )
  :serial t
  :components ((:file "typst-mode")))
  