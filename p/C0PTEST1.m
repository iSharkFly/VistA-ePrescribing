C0PTEST1 ; VEN/SMH - Scratch routine for testing ; 12/6/09 9:54pm
 ;;0.1;C0P;nopatch;noreleasedate
 Q
 ; The stuff below is to walk through all entries and test test test
T0
 D WALK^DICW(1130590010,"W DICWIENS,!")
 Q
T1
 ; dicwiens
 ; DICWHEAD
 D WALK^DICW(1130590010,"W $$GCN^C0PLKUP($P(^(0),U)),!")
 Q
T2
 D WALK^DICW(1130590010,"W:+DICWIENS<1000 $$RXNCUI^C0PLKUP($P(^(0),U,2)),!")
 Q
