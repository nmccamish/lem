(uiop:define-package :lem-typst-mode/lsp-config
    (:use :cl)
      (:export))
(in-package :lem-typst-mode/lsp-config)


(lem-lsp-mode:define-language-spec (typst-spec lem-typst-mode:typst-mode)
    :language-id "typst"
    :root-uri-patterns '("typ" "typst")
    :command '("tinymist" "lsp")
    :install-command "cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli"
    :readme-url "https://github.com/oxalica/nil"
    :connection-mode :stdio)