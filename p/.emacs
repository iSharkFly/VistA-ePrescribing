;; hooks for run before mode run
(defvar mumps-mode-hook nil)

;; keywords for higlight
(defconst mumps-font-lock-keywords-main
(list
;; Comments
'(";.*$" 0 font-lock-comment-face t)
;; Commands

'("\\<\\(T\\(?:R[EO]\\|[CS]\\)\\|t\\(?:r[eo]\\|[cs]\\)\\|[B-OQRSU-Xb-oqrsu-x]\\)\\>"
.. font-lock-keyword-face)

'("\\<\\(BREAK\\|CLOSE\\|DO\\|ELSE\\|FOR\\|GOTO\\| HALT\\|IF\\|JOB\\|KILL\\|LOCK\\|MERGE\\|NEW\\|OPEN \\|QUIT\\|READ\\|SET\\|T\\(?:COMMIT\\|R\\(?:ESTART \\|OLLBACK\\)\\|START\\)\\|USE\\|VIEW\\|WRITE\\|XE CUTE\\|break\\|close\\|do\\|else\\|for\\|goto\\|ha lt\\|if\\|job\\|kill\\|lock\\|merge\\|new\\|open\\ |quit\\|read\\|set\\|t\\(?:commit\\|r\\(?:estart\\ |ollback\\)\\|start\\)\\|use\\|view\\|\\(?:wri\\|x ecu\\)te\\)\\>"
.. font-lock-keyword-face)
;; Functions

'("\\<\\(\\$\\(?:FN\\|NA\\|Q[LS]\\|RE\\|ST\\|TR\\|fn\\|na\\|q[ls]\\|re\\|st\\|tr\\|[AC-GJLN-TVac-gjln-tv]\\)\\)\\>"
.. font-lock-function-name-face)

'("\\<\\(\\$\\(?:ASCII\\|CHAR\\|DATA\\|EXTRACT\\|F \\(?:IND\\|NUMBER\\)\\|GET\\|JUSTIFY\\|LENGTH\\|N\ \(?:AME\\|EXT\\)\\|ORDER\\|PIECE\\|Q\\(?:LENGTH\\| SUBSCRIPT\\|UERY\\)\\|R\\(?:ANDOM\\|EVERSE\\)\\|S\ \(?:ELECT\\|TACK\\)\\|T\\(?:EXT\\|RANSLATE\\)\\|VI EW\\|ascii\\|char\\|data\\|extract\\|f\\(?:ind\\|n umber\\)\\|get\\|justify\\|length\\|n\\(?:ame\\|ex t\\)\\|order\\|piece\\|q\\(?:length\\|subscript\\| uery\\)\\|r\\(?:andom\\|everse\\)\\|s\\(?:elect\\| tack\\)\\|t\\(?:ext\\|ranslate\\)\\|view\\)\\)\\>"
.. font-lock-function-name-face)
;; Program name
'("^[a-zA-Z0-9()%,]*[ \t]" . font-lock-type-face)))

;; call font-lock syntax agregators (may be we want to higlight something else?)
(defvar mumps-font-lock-keywords mumps-font-lock-keywords-main
"Default highlighting expressions for Mumps mode.")

;; initialization
(defun mumps-mode ()
(interactive)
(kill-all-local-variables)
(set (make-local-variable 'font-lock-defaults)
'(mumps-font-lock-keywords))
(setq major-mode 'mumps-mode)
(setq mode-name "Mumps")
(run-hooks 'mumps-mode-hook))

(provide 'mumps-mode)
