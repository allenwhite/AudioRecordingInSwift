# AudioRecordingInSwift
Practice using audio recording / speech recognition in swift 

APP records from the microphone, saves to a file, sends file to be transcribed and prints it out.
A LOT could be factored out here

Certainly have Massive View Controllers - however logic is all there in one app and pretty easy to digest.

Would recommend combining both button push and silence detection as a way to stop. Should also make use of thresholds 
to better detect silence, although many apps today still struggle with this and it is a difficult thing to test.

Combining this with a text parser would be very powerful, although a basic one could suffice in a small app
