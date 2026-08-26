(defsystem "lem-typst-mode"
  :depends-on ("lem/core"
               "lem-tree-sitter"
               )
  :serial t
  :components ((:file "typst-mode")
               (:file "lsp-config")
               (:module "preview" 
                :serial t
                :components ((:file "preview")))
               ))

