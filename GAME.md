# Master Design Document: Smart City Board Game

## 1. Executive Summary
This project is a hybrid physical-digital board game driven by an ESP32 microcontroller, an RFID reader, and a mobile frontend built in Flutter. Four players act as Mayors of distinct city-states, navigating a physical board to build infrastructure, manage resources, and survive dynamic events. The game utilizes a "Recalculate From Scratch" algorithm, ensuring flawless state management and dynamic scoring based on physical player movement and RFID card inputs.

---

## 2. System Architecture
The game operates on a client-server model bridging physical hardware and mobile software.

* **The Hardware (Server):** An ESP32 microcontroller serves as the game's core logic engine. It calculates physical movement based on inputs from a 1-10 spinner equipped with a magnetic encoder. An integrated RFID reader processes Special Cards (Policies, Events, Disasters).
* **The Network:** The ESP32 hosts a local WebSocket server for real-time, low-latency communication.
* **The Clients (UI):** Four players connect to the ESP32 via a Flutter-based mobile application. The app receives real-time JSON state updates and sends back player decisions (e.g., purchasing infrastructure). Roles are assigned randomly to the connected devices upon initialization.

---

## 3. Faction Asymmetry & Weighting
Players are assigned one of four distinct City Hubs. A city's Total Score is calculated using a weighted sum of four main Factors. The varying weights force players to adopt asymmetric strategies tailored to their city type.

| City Faction | Sustainability | Smart Factor | Livability | Economy |
| :--- | :--- | :--- | :--- | :--- |
| **Natural Resources Hub** | 40% | 10% | 20% | 30% |
| **Software Hub** | 10% | 40% | 30% | 20% |
| **Industrial Hub** | 10% | 20% | 20% | 50% |
| **Financial Hub** | 20% | 20% | 30% | 30% |

---

## 4. The Mathematical Engine
The ESP32 maintains a digital "Ledger" for each Mayor, storing their acquired infrastructure, capital, and active cards.

### 4.1 The 8 Core Metrics
1.  Emission (Negative Impact)
2.  Pollution Index / AQI (Negative Impact)
3.  Happiness Index (Positive)
4.  Biodiversity Health (Positive)
5.  Community Trust (Positive)
6.  Tech Integration (Positive)
7.  Economic Output (Positive)
8.  Infrastructure Efficiency (Positive)

### 4.2 The Factor Formulas
*Note: Negative metrics are inverted using a Maximum scale value (e.g., Max - Emission) so that lower pollution yields a higher numerical score.*

* **Sustainability** = [Biodiversity + (Max - Emission) + (Max - Pollution)] / 3
* **Smart** = [Tech Integration + Infrastructure Efficiency] / 2
* **Livability** = [Happiness + Community Trust + Infrastructure Efficiency + (Max - Pollution)] / 4
* **Economy** = [Economic Output + Tech Integration + Community Trust] / 3

---

## 5. Core Gameplay Loop & Economy

### 5.1 Movement
Players spin the 1-10 wheel. The ESP32 calculates their exact position on the 1D mathematical track representing the board's spiral grid layout.

### 5.2 Purchasing Infrastructure
If a player lands on a standard Infrastructure Tile, the ESP32 checks their Bank Balance.
1.  The ESP32 sends a WebSocket JSON payload to that specific player's Flutter app prompting a purchase.
2.  If the player taps "Buy", the app responds to the ESP32.
3.  The ESP32 deducts the cost from their Bank Balance and adds the tile ID to their Ledger.

### 5.3 The Income System
Each time a Mayor completes a lap (passes the track's starting index), their current **Economic Output** metric value is deposited into their Bank Balance as spendable capital.

---

## 6. Progression, Ascension, and Endgame

### 6.1 The Track Rings
* **Outer Ring (Developing Nations):** A longer track where players start. Laps are slower, meaning Disasters and Policies last longer in real-time.
* **Inner Ring (Developed Nations):** A shorter track featuring upgraded infrastructure base values. Laps are faster, creating a frantic, high-stakes pacing where effects expire rapidly.

### 6.2 Ascension Mechanics
Cities begin with a baseline score of 1,000 points. 
* If a city's Total Score reaches **4,000 points**, the Mayor ascends. Their physical piece is moved to the Inner Ring, and the ESP32 seamlessly shifts their tracking logic to the shorter Inner Ring track geometry.

### 6.3 Win/Loss Conditions
* **Elimination:** If a Mayor's Total Score drops to **200 points**, their city collapses, and they lose the game.
* **Victory:** The game concludes immediately when any Mayor completes exactly **6 laps within the Inner Ring**. At that moment, the Mayor with the highest Total Score is declared the winner.

---

## 7. The Card System (Special Tiles)
Fixed coordinates on the board act as Special Zones. When landed upon, the player taps one of 20 physical cards to the RFID reader. Card duration is tracked by the individual Mayor's lap count. During recalculation, if `Current Lap > (Lap Applied + Duration)`, the card is automatically excluded.

### 7.1 Policy Cards (Player Choice)
* **Carbon Tax:** Choice A (Aggressive) | Choice B (Moderate)
* **Plastic Ban:** Choice A (Immediate Ban) | Choice B (Phased Approach)
* **Public Transit Subsidy:** Choice A (Free Rides) | Choice B (Discounted Fares)
* **Green Energy Subsidy:** Choice A (Solar Focus) | Choice B (Wind Focus)
* **Urban Density Policy:** Choice A (Build Up) | Choice B (Build Out)

### 7.2 Event-1 Cards (Player Choice)
* **Community Tree Planting:** Choice A (City Funded) | Choice B (Volunteer Led)
* **Clean River Restoration:** Choice A (Corporate Sponsor) | Choice B (Public Initiative)
* **Green Startup Boom:** Choice A (Tax Breaks) | Choice B (Let It Be)
* **Community Recycling Drive:** Choice A (Rewards System) | Choice B (Mandatory Fines)
* **Eco-Tourism Promotion:** Choice A (Luxury Focus) | Choice B (Backpacker Focus)

### 7.3 Event-2 Cards (Forced Outcome)
* **Eco-Tourism Boom:** Outcome A (Respectful Visitors) | Outcome B (Reckless Crowds)
* **Public Transport Adoption Surge:** Outcome A (Permanent Shift) | Outcome B (Passing Fad)
* **Wetland Regeneration Success:** Outcome A (Biodiversity Explosion) | Outcome B (Natural Buffer)
* **Climate Technology Grant:** Outcome A (Unrestricted Cash) | Outcome B (Hardware Upgrade)
* **Migratory Bird Phenomenon:** Outcome A (Peaceful Stopover) | Outcome B (Agricultural Pests)

### 7.4 Disaster Cards (Forced Outcome)
* **Forest Fire:** Outcome A (Favorable Winds) | Outcome B (Winds Blow Inward)
* **Industrial Accident:** Outcome A (Quick Containment) | Outcome B (Widespread Contamination)
* **Heatwave:** Outcome A (The Grid Holds) | Outcome B (Rolling Blackouts)
* **Flood:** Outcome A (Flash Flood) | Outcome B (Standing Water)
* **Drought:** Outcome A (Mild Dry Spell) | Outcome B (Crop Failure)

---

## 8. Infrastructure Tiles List
These 48 standard tiles can be purchased. Each tile modifies Immediate Factor Scores (Sustainability, Smart, Livability, Economy) and Future Base Metrics.

1. Solar Power Plant
2. Wind Farm
3. Smart Energy Grid
4. Hydroelectric Dam
5. Desalination Plant
6. Water Treatment Plant
7. Reservoir System
8. Urban Forest
9. Wetland Restoration
10. City Park Network
11. Recycling Plant
12. Green Housing Complex
13. Vertical Farming Center
14. Mass Transit System
15. Highway Expansion
16. Industrial Park
17. Eco Tourism Park
18. Research & Innovation Center
19. Urban Cooling System
20. Fire Control Station
21. Data Center
22. High-Speed Rail
23. Vertical Farm
24. EV Charging Network
25. Waste-to-Energy Plant
26. BRT System
27. Smart Traffic Lights
28. Green Roof Initiative
29. Geothermal Plant
30. Smart Streetlights
31. Autonomous Vehicle Hub
32. Microgrid Network
33. Carbon Capture Plant
34. Biomass Power Plant
35. Smart Water Meters
36. Hydrogen Refueling Station
37. Ocean Thermal Plant
38. Community Garden
39. Offshore Wind Farm
40. Fiber Optic Network
41. Smart Parking System
42. E-Bike Sharing System
43. Flood Wall / Levee
44. Seawater Greenhouse
45. Hyperloop Terminal
46. Automated Waste Sorting
47. Floating Solar Farm
48. Underground Freight Network

---

## 9. Player Interface (Mobile App UI)
The Flutter application serves as the "Mayor's Terminal" replacing physical UI elements on the board.
* **Header:** Displays City Type and a real-time Bank Balance counter.
* **Dashboard:** Features a dynamic Radar Chart visualizing the 4 main Factors.
* **Status Log:** An active list of current Disasters and Policies with lap countdowns.
* **Progression:** A linear bar tracking the journey to the 4,000-point Ascension threshold.
* **Interaction:** Dialog modals for handling infrastructure purchases and Policy/Event decisions.
