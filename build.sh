#!/bin/sh
emacs --batch -Q                        \
  --visit helper.org --load init.el     \
  --visit resume.org                    \
  --eval '(org-latex-export-to-latex)'  \

xelatex resume.tex -interaction=nonstopmode
