Glukloader
==========

Glukloader is the OS X desktop uploader of Dexcom G4 with Share/Dexcom G5 data to [Glukit](http://www.mygluk.it/). 

The current code is useable but in a proof-of-concept phase. 
  
Development
-----------

Glukloader expects a `GlukitSecrets.swift` with the `clientId` and `clientSecret` values.

Something like:

```
struct GlukitSecrets {
    static let clientId = "***REMOVED***"
    static let clientSecret = "***REMOVED***"
}
```
