// /// Register map for the PFS Station's 6 lanes (4 visible + 2 reached by
// /// horizontal scroll). Each lane has its own LED output (lights up when
// /// this lane is the one matched to the currently scanned ESN) and harness
// /// sensor input (confirms the physical harness is actually connected).
// ///
// /// TODO: replace these placeholder addresses with the real ones once
// /// Simpson/Autopeepal confirm the PLC register list.
// class PsfLaneRegisters {
//   const PsfLaneRegisters({
//     required this.laneIndex,
//     required this.ledOutputRegister,
//     required this.harnessConnectedInputRegister,
//   });

//   /// 0-based lane index (0..5 for the 6 lanes).
//   final int laneIndex;

//   /// Write 1 to turn this lane's LED on, 0 to turn it off.
//   final int ledOutputRegister;

//   /// Read: PLC reports 1 when the harness is physically connected into
//   /// this lane's ECU slot, 0 otherwise.
//   final int harnessConnectedInputRegister;
// }

// const List<PsfLaneRegisters> psfLaneRegisterMap = [
//   PsfLaneRegisters(laneIndex: 0, ledOutputRegister: 40101, harnessConnectedInputRegister: 40111),
//   PsfLaneRegisters(laneIndex: 1, ledOutputRegister: 40102, harnessConnectedInputRegister: 40112),
//   PsfLaneRegisters(laneIndex: 2, ledOutputRegister: 40103, harnessConnectedInputRegister: 40113),
//   PsfLaneRegisters(laneIndex: 3, ledOutputRegister: 40104, harnessConnectedInputRegister: 40114),
//   PsfLaneRegisters(laneIndex: 4, ledOutputRegister: 40105, harnessConnectedInputRegister: 40115),
//   PsfLaneRegisters(laneIndex: 5, ledOutputRegister: 40106, harnessConnectedInputRegister: 40116),
// ];
/// Register map for the PFS Station's 6 lanes (4 visible + 2 reached by
/// horizontal scroll). Each lane has its own LED output (lights up when
/// this lane is the one matched to the currently scanned ESN) and harness
/// sensor input (confirms the physical harness is actually connected).
///
/// TODO: replace these placeholder addresses with the real ones once
/// Simpson/Autopeepal confirm the PLC register list.
class PsfLaneRegisters {
  const PsfLaneRegisters({
    required this.laneIndex,
    required this.ledOutputRegister,
    required this.harnessConnectedInputRegister,
  });

  /// 0-based lane index (0..5 for the 6 lanes).
  final int laneIndex;

  /// Write 1 to turn this lane's LED on, 0 to turn it off.
  final int ledOutputRegister;

  /// Read: PLC reports 1 when the harness is physically connected into
  /// this lane's ECU slot, 0 otherwise.
  final int harnessConnectedInputRegister;
}

const List<PsfLaneRegisters> psfLaneRegisterMap = [
  PsfLaneRegisters(laneIndex: 0, ledOutputRegister: 40101, harnessConnectedInputRegister: 40111),
  PsfLaneRegisters(laneIndex: 1, ledOutputRegister: 40102, harnessConnectedInputRegister: 40112),
  PsfLaneRegisters(laneIndex: 2, ledOutputRegister: 40103, harnessConnectedInputRegister: 40113),
  PsfLaneRegisters(laneIndex: 3, ledOutputRegister: 40104, harnessConnectedInputRegister: 40114),
  PsfLaneRegisters(laneIndex: 4, ledOutputRegister: 40105, harnessConnectedInputRegister: 40115),
  PsfLaneRegisters(laneIndex: 5, ledOutputRegister: 40106, harnessConnectedInputRegister: 40116),
];

