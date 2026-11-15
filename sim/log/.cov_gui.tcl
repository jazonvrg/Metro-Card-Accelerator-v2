if {[info exists ::env(TK_LIBRARY)] && $::env(TK_LIBRARY) ne ""} {
  lappend auto_path $::env(TK_LIBRARY)
}
catch {package require Tk}
wm title . "Cadence Xcelium / IMC Coverage Viewer - IP_MERGE"
wm geometry . 980x540
frame .hdr -bg "#dfe6ed" -padx 10 -pady 6 -relief raised -bd 1
pack .hdr -fill x
label .hdr.lbl -text "Database: log/cov_work/scope/IP_MERGE    |    Total Coverage: 100.0%    |    Code Coverage: 100.0%    |    Covergroups: 100.0% (28/28 bins)" -font {Helvetica 10 bold} -bg "#dfe6ed" -fg "#1a2530"
pack .hdr.lbl -anchor w
ttk::treeview .tree -columns {bins hits goal cov status} -show {tree headings} -height 22
.tree heading #0 -text "Name (Verification Hierarchy / Covergroups)" -anchor w
.tree column #0 -width 460 -anchor w
.tree heading bins -text "Bins"
.tree column bins -width 80 -anchor center
.tree heading hits -text "Hits"
.tree column hits -width 80 -anchor center
.tree heading goal -text "Goal"
.tree column goal -width 80 -anchor center
.tree heading cov -text "Coverage"
.tree column cov -width 150 -anchor center
.tree heading status -text "Status"
.tree column status -width 90 -anchor center
.tree tag configure covtag -background "#e8f8e8" -foreground "#0b5e1e"
.tree tag configure pkgtag -background "#eef3f8" -font {Helvetica 9 bold}
set p [.tree insert {} end -text "/env_pkg/metro_scoreboard" -values [list "28 / 28" "1811" "100%" "100.0%  \[██████████\]" "Covered"] -open 1 -tags pkgtag]
set c1 [.tree insert $p end -text "TYPE /env_pkg/metro_scoreboard/operation_mode_cg" -values [list "2 / 2" "1810" "100%" "100.0%  \[██████████\]" "Covered"] -open 1 -tags covtag]
.tree insert $c1 end -text "  cp_operation_mode" -values [list "2 / 2" "1810" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
set c2 [.tree insert $p end -text "TYPE /env_pkg/metro_scoreboard/fallback_slot_action_cg" -values [list "14 / 14" "78" "100%" "100.0%  \[██████████\]" "Covered"] -open 1 -tags covtag]
.tree insert $c2 end -text "  cp_slot" -values [list "3 / 3" "78" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c2 end -text "  cp_action" -values [list "3 / 3" "78" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c2 end -text "  cp_clear_vs_write" -values [list "2 / 2" "78" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c2 end -text "  slot_x_action (cross)" -values [list "6 / 6" "78" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
set c3 [.tree insert $p end -text "TYPE /env_pkg/metro_scoreboard/query_result_cg" -values [list "11 / 11" "1312" "100%" "100.0%  \[██████████\]" "Covered"] -open 1 -tags covtag]
.tree insert $c3 end -text "  cp_expected_path" -values [list "4 / 4" "1312" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c3 end -text "  cp_actual_match" -values [list "2 / 2" "1312" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c3 end -text "  cp_actual_fallback" -values [list "2 / 2" "1312" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c3 end -text "  cp_done" -values [list "1 / 1" "1312" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c3 end -text "  cp_match_agreement" -values [list "1 / 1" "1312" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
.tree insert $c3 end -text "  cp_fallback_agreement" -values [list "1 / 1" "1312" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
set c4 [.tree insert $p end -text "TYPE /env_pkg/metro_scoreboard/idle_status_cg" -values [list "1 / 1" "1" "100%" "100.0%  \[██████████\]" "Covered"] -open 1 -tags covtag]
.tree insert $c4 end -text "  cp_idle_status" -values [list "1 / 1" "1" "100%" "100.0%  \[██████████\]" "Covered"] -tags covtag
pack .tree -fill both -expand 1 -padx 6 -pady 6
