Feature: Bidding platform conformance
  # Gherkin as a shared, platform-neutral scenario language — not tied to any particular
  # runner. A platform repo may wire these into Cucumber/XCTest/Jest/etc., or simply use them
  # as the checklist of behaviors its own native test suite must cover under different names.
  # Each Scenario cites the domain/*.md rule(s) it verifies.

  Background:
    Given a Lot "L1" in an Open auction with startingBidPrice 100, incrementPrice 10,
      extendedIncrementPrice 25, and no bids yet

  # SPEC-LOT-002, SPEC-BID-001
  Scenario: Bidding is only possible while the lot is Running or Extended
    Given Lot "L1" has running state "Not Running"
    Then the "Place Bid" and "Place Max Bid" controls are disabled
    When Lot "L1" transitions to running state "Running"
    Then the "Place Bid" and "Place Max Bid" controls are enabled
    When Lot "L1" transitions to running state "Finished"
    Then the "Place Bid" and "Place Max Bid" controls are disabled

  # SPEC-LOT-003
  Scenario: An unrecognized running state fails closed
    Given Lot "L1" reports running state "SomeNewState" that the client does not recognize
    Then the "Place Bid" and "Place Max Bid" controls are disabled
    And a generic "bidding isn't open" message is shown, not an error

  # SPEC-BID-002
  Scenario: Minimum next bid uses the normal increment while Running
    Given Lot "L1" has running state "Running" and no bids yet
    Then the suggested/minimum next bid is 110

    Given the highest bid on Lot "L1" becomes 150
    Then the suggested/minimum next bid is 160

  # SPEC-EXT-002, SPEC-BID-002
  Scenario: Minimum next bid switches to the extended increment once Extended
    Given Lot "L1" has running state "Extended" and the highest bid is 150
    Then the suggested/minimum next bid is 175
    And a bid of 160 is rejected as below the minimum

  # SPEC-EXT-001, SPEC-EXT-003
  Scenario: A late bid extends the deadline, and can extend again
    Given Lot "L1" has running state "Running" with endDate "T"
    When a valid bid lands within the extension trigger window before "T"
    Then Lot "L1" transitions to running state "Extended"
    And the effective closing time becomes some "extendedEndDate" later than "T"
    When another valid bid lands within the trigger window of the new "extendedEndDate"
    Then the effective closing time moves again to a further "extendedEndDate"

  # SPEC-BID-003
  Scenario: The server's rejection is authoritative even if the client's own check passed
    Given the client believes the minimum next bid is 110
    But another bidder's bid of 120 lands moments before this bidder submits 110
    When this bidder submits a bid of 110
    Then the server rejects it
    And the client surfaces the server's rejection rather than assuming success

  # SPEC-MAX-001, SPEC-MAX-004
  Scenario: Placing a Max Bid can immediately change the leading amount
    Given Lot "L1" has running state "Running" and the highest bid is 100
    When bidder A places a Max Bid of 200
    Then Lot "L1"'s highest bid becomes at least 100 plus one increment, attributed to bidder A
    And the client refetches live data and history immediately after the Max Bid succeeds,
      rather than waiting only for a live-update push

  # SPEC-MAX-003
  Scenario: An active max bid still covering the current highest counts as leading
    Given bidder A has an Active Max Bid of 300 on Lot "L1"
    And the current highest bid on Lot "L1" is 250, placed by bidder A's own max bid
    Then bidder A is shown as leading

    When bidder B places a max bid that pushes the highest bid to 320
    Then bidder A's Max Bid of 300 no longer covers the highest bid
    And bidder A is shown as outbid, with a visible warning

  # SPEC-RT-002
  Scenario: A stale or out-of-order push never regresses the displayed highest bid
    Given the client currently holds a highest-bid update for Lot "L1" with amount 500 and
      createdAt "T2"
    When a push arrives for Lot "L1" with amount 480 and createdAt "T1" (earlier than "T2")
    Then the displayed highest bid remains 500
    And the stale push is discarded, not applied

  # SPEC-RT-004
  Scenario: A bidder's own just-placed bid is a floor until confirmed
    Given bidder A submits a bid of 400 on Lot "L1" and it succeeds
    When an immediately-following live-data fetch still returns a highest bid of 380 (a
      stale read)
    Then the client displays 400, not 380
    When a subsequent fetch or push reports a highest bid of 400 or more
    Then the client drops the local floor and trusts the fetched/pushed data normally

  # SPEC-RES-001, SPEC-RES-002
  Scenario: Reserve price is never disclosed, and never gates bidding
    Given Lot "L1" has a reserve price configured (value withheld from the client)
    Then the client can only ever observe "reserve met: true/false", never a figure
    When the reserve becomes met
    Then bidding remains open exactly as it would if the reserve were not yet met

  # SPEC-AUC-002
  Scenario: Non-open auctions hide bidding history and disable Max Bid
    Given Lot "L1" belongs to a non-open (sealed) auction
    Then public bidding history is not shown for Lot "L1"
    And the "Place Max Bid" control is not shown for Lot "L1"

  # SPEC-BID-005
  Scenario: Bidding history masks other bidders' identities
    Given Lot "L1" has bids from bidder A (the viewer) and bidder B
    When the viewer (bidder A) views the bidding history
    Then bidder A's own row is clearly marked as theirs
    And bidder B's row shows only a masked identity, never bidder B's full name or contact
