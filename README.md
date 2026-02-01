RehabPoints – Medlemsbaserat Poäng- och Belöningssystem
RehabPoints är ett smart kontrakt på Ethereum Sepolia som hanterar:
- Medlemskap
- Poängintjäning
- Poängöverföringar
- Belöningar
- Inlösen
- Admin‑kontroll
- Eventloggning
- Säker hantering av ETH
Kontraktet är skrivet i Solidity 0.8.28 och är gasoptimerat med:
- uint96 / uint128
- immutable
- custom errors
- unchecked block
- cooldown‑logik för att förhindra missbruk

🚀 Deployment
Kontraktet är deployat på Sepolia:
## 📌 Kontraktsadress
**0x289093350BDcCF26BA927345edf3872E7081CDf6**

Verifierad på Etherscan:  
https://sepolia.etherscan.io/address/0x289093350bdccf26ba927345edf3872e7081cdf6#code

Kontraktet deployades med Foundry:


📚 Funktionalitet
👥 Medlemskap
- joinAsMember() – vem som helst kan bli medlem
- isMember(address) – kontrollera medlemskap
- onlyMember – skyddar funktioner som kräver medlemskap
- Admin blir automatiskt medlem i konstruktorn

⭐ Poängsystem
- earnPoints(amount, reason)
- medlem tjänar poäng
- 24h cooldown för att förhindra spam
- första intjäningen är alltid tillåten
- grantPoints(to, amount, reason)
- admin tilldelar poäng
- kräver att mottagaren är medlem
- transferPoints(to, amount)
- överför poäng mellan medlemmar
- validerar: medlemskap, saldo, nolladress, nollbelopp
- getPoints(address) – hämta saldo
- _addPoints() – intern funktion med invariant‑kontroll

🎁 Belöningar
- RewardType enum
- Reward struct
- setReward(type, cost, active) – admin uppdaterar belöning
- getReward(type) – hämta belöning
- redeemPoints(amount, reason) – medlem löser in poäng

🛡 Admin
- admin är immutable
- onlyAdmin skyddar alla administrativa funktioner

⚙ Gasoptimering & Säkerhet
Kontraktet använder flera optimeringar:
- uint96 / uint128 för att minska storage‑kostnader
- immutable admin för billigare läsningar
- custom errors för lägre gas än revert‑strängar
- cooldown‑logik för att förhindra missbruk
- strict access control via onlyAdmin och onlyMember
- revert i receive/fallback för att förhindra oavsiktlig ETH‑inlåning

**Gasrapport från deployment:**  
Total gas: 2017270  
Gaspris: 1.104208976 gwei  
ETH betalt: 0.00222748764101552 ETH  
Bytecode‑storlek: 8413 bytes


💰 Ether-hantering
Kontraktet ska inte ta emot ETH.
- receive() – revertar alltid
- fallback() – revertar alltid
Detta skyddar användare från att skicka ETH av misstag.

📡 Events
- MemberJoined
- PointsEarned
- PointsTransferred
- PointsRedeemedGeneric
- RewardUpdated
- AdminPointsGranted

🧪 Testning (Foundry)
Testerna täcker:
- Medlemskap
- Poängintjäning + cooldown
- Admin‑tilldelning
- Poängöverföringar
- Inlösen
- Reward‑system
- Fallback/receive
- Alla felvägar (custom errors + require‑strängar)

**Utvecklingsmiljö:**  
Solidity 0.8.28  
Foundry (Forge + Cast)  
Sepolia Testnet via Alchemy  
Etherscan API  
Windows 11 + PowerShell

