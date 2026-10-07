;;; init.el -*- lexical-binding: t; -*-

;; This file controls what Doom modules are enabled and what order they load
;; in. Remember to run 'doom sync' after modifying it!

(doom! :input

       :completion
       (vertico +icons)           ; the sensible, modern completion framework
       ;; company                ; the old reliable completion engine

       :ui
       doom                      ; what makes DOOM look the way it does
       doom-dashboard            ; a nifty splash screen for Emacs
       doom-quit                 ; DOOM quit-messages
       hl-todo                   ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       modeline                  ; snazzy, Atom-inspired modeline, plus API
       ophints                   ; highlight the region an operation acts on
       (popup +defaults)         ; tame sudden yet inevitable temporary windows
       treemacs                  ; a project drawer, like neotree but cooler
       (vc-gutter +pretty)       ; vcs diff in the fringe
       vi-tilde-fringe           ; fringe tildes to mark beyond EOB
       which-key                 ; run <leader> to see what's possible

       :editor
       (evil +everywhere)        ; come to the dark side, we have cookies
       file-templates            ; auto-snippets for empty files
       fold                      ; (nigh) universal code folding
       (format +onsave)          ; automated code formatting
       multiple-cursors          ; editing in many places at once
       snippets                  ; my elves. They type so I don't have to

       :emacs
       (dired +icons)            ; making dired pretty [functional]
       electric                  ; smarter, keyword-based electric-indent
       undo                      ; persistent, smarter undo for your inevitable mistakes
       vc                        ; version-control and here-be-dragons

       :term
       vterm                     ; the best terminal emulation in Emacs

       :checkers
       syntax                    ; tasing you for every semicolon you forget

       :tools
       ansible
       (debugger +lsp)           ; FIXME configuring debugger on demand
       direnv
       docker
       editorconfig              ; let someone else argue about tabs vs spaces
       (eval +overlay)           ; run code, see result
       lookup                    ; navigate your code and its documentation
       (lsp +peek)               ; M-x vscode
       (magit +forge)            ; a git porcelain for Emacs
       make                      ; run make tasks from Emacs
       (terraform +lsp)          ; infrastructure as code
       tree-sitter               ; syntax and parsing, sitting in a tree...

       :os
       (:if (featurep :system 'macos) macos) ; improve STEM application performance

       :lang
       (cc +lsp)                 ; C > C++ == 1
       common-lisp               ; if you've seen one Lisp, you've seen them all
       (dart +lsp)               ; paint ui and not much else
       data                      ; config/data formats (csv, sql, etc.)
       emacs-lisp                ; drown in parentheses
       (go +lsp)                 ; the hipster's brew
       (javascript +lsp)         ; all(hope(leave(ye(who(enter(here))))))
       (json +lsp)               ; At least it ain't XML
       (markdown +lsp)           ; write docs for people to ignore
       (nix +lsp)                ; I hereby declare "nix geht mehr!"
       (org +pretty)             ; organize your plain life in plain text
       (python +lsp +pyright)    ; beautiful is better than ugly
       (ruby +lsp)               ; 1.step {|i| p "Ruby is dead"}
       (rust +lsp)               ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       (sh +lsp)                 ; she sells {ba,z}sh shells on the C xor
       (yaml +lsp)               ; JSON, but readable

       :config
       (default +bindings +smartparens))
