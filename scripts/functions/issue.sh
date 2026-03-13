
install_motd() {
    print_section "MOTD  //  TOMB WORLD OPERATOR BRIEFING"

    sudo tee /etc/motd > /dev/null << 'MOTD'

  ── OPERATOR CLEARANCE CONFIRMED ───────────────────────────────────────────

  NECRODERMIS has granted you root-level access to this tomb world node.
  The following directives are non-negotiable.

  ── SECURITY PROTOCOL ──────────────────────────────────────────────────────

  This system has been dormant. Attack vectors are unknown.
  Canoptek perimeter wards are active but not infallible.

  · Root access is a weapon. Wield it with intent, not habit.
  · Unverified packages are dimensional rifts. Do not open them.
  · Networking is a vulnerability. Know what you expose.
  · Your sudo log is a diagnostic record. Review it.
  · Encryption is a stasis field. Enable it where it matters.

  The Silent King did not survive 60 million years by being careless.
  Neither will you.

  ── OPERATIONAL GUIDANCE ───────────────────────────────────────────────────

  · Run 'yay -Syu' regularly — the tomb world must stay current.
  · Review ~/.local/share/necrodermis/install.log if systems misbehave.
  · necrodermis-uninstall will restore order if the dermal layer must go.
  · Back up your engram banks. /home is not eternal. NECRODERMIS is.

  ── CONTINGENCY PROTOCOL ───────────────────────────────────────────────────

  If this node fails — if configs corrupt, packages break, the tomb
  collapses into chaos — do not panic. NECRODERMIS is eternal.

  The installer remembers. The repo endures. Run it again.
  The tomb world always rebuilds.

  ──────────────────────────────────────────────────────────────────────────
MOTD

    print_ok "Operator briefing inscribed  ${DG}//  /etc/motd${NC}"
}
