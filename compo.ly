upper = \relative c'' {
  \clef treble
  \key c \major
  \time 6/8
}

lower = \relative c {
  \clef bass
  \key c \major
  \time 6/8
  
  g8 bes d g d bes |
  g bes d g d bes |
  f bes d g d bes |
  f bes d g d bes |
  ees bes d g d bes |
  ees bes d g d bes |
  % either
  ges ais cis ges cis ais |
  ges ais cis ges cis ais |
  % or
  d bes d g d bes |
  d bes d g d bes |
  d a d g d bes |
  d a d g d bes |
  d a d ges d bes |
  d a d ges d bes |
}

\score {
  \new PianoStaff <<
    \set PianoStaff.instrumentName = #"Piano  "
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
  \midi { }
}


