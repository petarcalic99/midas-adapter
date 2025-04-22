 # Midas Wrapper

 Description of the ERC4626 wrapper for the midas mTokens. The wrapper allows to interact with the any mToken through the ERC4626 interface, making it compatible for deploying a Principal Token contract.

## Important note
Even though the mTokens support instant deposits and redeems, we decided to revert them here as they might become unavailble for some periods of time. In the commits you may notice an the deposit was added but for simplicity of the wrapper we decided to remove it in the end

 ## Architecture

 - The wrapper is built on top of `Spectra4626Wrapper`, which itself inherits Openzeppelin's ERC4626 implementation and AccessManager. 
 - The contract is initialized with:
   - the address of the mToken
   - the address of the underlying token (should be checked in the mToken for availability)
   - the address of the instant deposit contract
   - the address of the instant redeem contract.
   - the address of the Access Manager that acts as initial Authority
 - The wrapper overrides
   - `_convertToShares` and `_convertToShares`: convert between shares and underlying asset. Functions from the instantDeposit and redeem contracts were replicated excluding the fee. In the previewRedeem function on the other hand the fee is taken into account.
   - `withdraw` and `redeem` and `deposit` and `mint`: Not Implemented by default.

 ## Ressources

 - [midas mToken addresses ](https://docs.midas.app/resources/smart-contracts-addresses)
