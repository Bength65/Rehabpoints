# RehabPoints – Medlemsbaserat Poäng- och Belöningssystem

RehabPoints är ett smart kontrakt på Ethereum Sepolia som hanterar:
- Medlemskap
- Poängintjäning
- Poängöverföringar
- Belöningar
- Inlösen
- Admin‑kontroll
- Eventloggning
- Ether‑mottagning

Kontraktet är skrivet i Solidity 0.8.28 och är gasoptimerat med:
- `uint96` / `uint128`
- `immutable`
- `custom errors`
- `unchecked` block

## 🚀 Deployment
Kontraktet är deployat på Sepolia:

**Contract Address:**  
`0x73108ab1E119d1a0987FADFD1e622186B8F7f133`

**Deployer:**  
`0x066B866a5BB8E1832a7b792A56fC87578F5F4192`

Kontraktet är verifierat på Etherscan.

---

# 📚 Funktionalitet

## 👥 Medlemskap
- `joinAsMember()` – vem som helst kan bli medlem  
- `isMember(address)` – kontrollera medlemskap  
- `onlyMember` – modifierare för att skydda funktioner  

## ⭐ Poängsystem
- `earnPoints(amount, reason)` – medlem tjänar poäng  
- `grantPoints(to, amount, reason)` – admin tilldelar poäng  
- `transferPoints(to, amount)` – överför poäng mellan medlemmar  
- `getPoints(address)` – hämta saldo  
- `_addPoints()` – intern funktion  

## 🎁 Belöningar
- `RewardType` enum  
- `Reward` struct  
- `setReward(type, cost, active)` – admin uppdaterar belöning  
- `getReward(type)` – hämta belöning  
- `redeemReward(type)` – medlem löser in belöning  

## 🛡 Admin
- `admin` är immutable  
- `onlyAdmin` modifier  

## ⚙ Gasoptimering & Säkerhet
- custom errors  
- unchecked block  
- uint96/uint128  
- immutable admin  

## 💰 Ether-hantering
- `receive()` – tar emot ETH  
- `fallback()` – fångar okända anrop  

## 📡 Events
- `MemberJoined`  
- `PointsEarned`  
- `PointsTransferred`  
- `PointsRedeemed`  
- `RewardUpdated`  
- `AdminPointsGranted`  
- `EtherReceived`  
- `FallbackCalled`  

---

# 🧪 Testning (Foundry)
```bash
forge test