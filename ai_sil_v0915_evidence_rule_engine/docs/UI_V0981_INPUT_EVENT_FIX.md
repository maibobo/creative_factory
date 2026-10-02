# v0.9.8.1 Requirement Editor Event Fix

v0.9.8 used control ID `1032` for both the Test Requirement EDIT control and the AI SIL Engineer button. EDIT notifications could therefore be mis-dispatched as a button click.

v0.9.8.1:
- changes the requirement editor ID to `1101`;
- consumes EDIT notifications before button dispatch;
- dispatches button actions only for `BN_CLICKED`.

Expected result: typing or pasting in the Test Requirement field never opens the AI SIL Engineer dialog. The dialog is shown only when its explicit button is clicked and a `capability_missing` TestPlan exists.
