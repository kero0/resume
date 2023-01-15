(require 'org)
(require 'ox-latex)

(setq org-confirm-babel-evaluate nil
      org-babel-lang-list '("emacs-lisp")
      org-export-use-babel t
      org-babel-header-args:emacs-lisp '((lexical . t)))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)))

(org-babel-execute-buffer)
