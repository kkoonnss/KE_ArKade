### Technical Architecture Specification: The Arena Abstraction Platform

#### 1\. Executive Vision: From Projection to Physical Operating System

The evolution of interactive installations has reached a critical pivot point. Traditionally, developers have built "projection games"—bespoke, isolated experiences where logic is hard-coded to a specific projector's output and a specific room's geometry. To scale across diverse venues and genres, we must shift toward an  **arena operating system** . This architectural abstraction decouples the physical environment from the digital experience, allowing a single interactive platform to "boot up" in any space. By establishing this translation layer, we gain immense leverage: a single venue calibration supports a library of interchangeable games, and a single game instantly adapts to a new physical floor plan.The following table contrasts the traditional "Projector-first" workflow with our high-leverage "Arena-first" model:| Traditional "Projector-First" Workflow | Proposed "Arena-First" Model || \------ | \------ || Focuses on "showing a rectangle on a wall." | Focuses on defining the semantic meaning of space. || Game logic is coupled to keystone and resolution. | Game logic targets a canonical digital model. || Every venue requires a custom build of the game. | Every venue requires a one-time calibration. || Content is a single, monolithic executable. | Content consists of modular "Software Cartridges." || Limited scaling: One game per installation. | High leverage: Any game works in any calibrated arena. |  
The core mission of this architecture is defined by a single guiding question:  **"What is the smallest prototype that proves arena abstraction works?"**Our answer is the  **Arena Compiler/Paintbrush Workflow** : An operator draws an arena using a physical paintbrush or digital tool, assigns colors to semantic zones, and the Arena Compiler converts that image into structured arena data. A game then reads this data and populates itself without further manual coding. This proves that the real invention is the translation layer between a real-world physical space and a reusable digital arena model.This vision is realized through a specific structural framework that separates physical alignment from creative content, ensuring the platform remains modular, scalable, and venue-agnostic.

#### 2\. The Engine-Agnostic Data Hierarchy

A critical requirement for portability is the separation of venue-specific data from game-specific logic. In festival or touring environments, lighting and geometry change constantly. By isolating these variables, we ensure that a game developer never needs to know the specific hardware serials or exact dimensions of a warehouse floor to build a functional experience.The platform utilizes three core entities to manage this separation:

* **Scene:**  The "Physical Identity" of the space. This is the  **authoritative source of truth**  storing physical venue alignment, device calibration (projector transforms and camera parameters), and controller defaults. While projectors may have internal memories, they are treated merely as a convenience layer; the Scene data remains the master.  
* **Level:**  The "Semantic Identity" of the space. This is an interchangeable content variant or remap for a specific Scene. It stores semantic masks (the "meaning" of different areas), overlays, thumbnails, and derived geometry used to inform game mechanics.  
* **Cartridge:**  The "Logic Identity." These are packaged game bundles containing assets and code. Each Cartridge includes a manifest that declares which semantic layers it requires to function (e.g., "This game requires a 'Path' and a 'Goal'").This "Cartridge-style" modularity eliminates cross-game dependencies. An operator can swap between a racing game and a puzzle game in seconds because both games simply read the existing Scene and Level data. This efficiency allows for rapid iteration and the ability to return to a previously calibrated venue and resume operation in under two minutes.From these high-level entities, we move to the specific semantic data that allows games to "interpret" the physical world.

#### 3\. The Semantic Mapping Pipeline & Standardized Palette

To achieve engine-agnosticism, the platform employs a "translation layer" between physical space and the digital runtime. Instead of a game looking at a raw video feed, it looks at a  **Semantic Map** . This allows games to interpret space abstractly: a "Hazard" zone remains a hazard whether it is a physical pillar in a gallery or a digital lava pit in a forest.The  **Standardized Semantic Palette (V1)**  defines the vocabulary used by all cartridges:| Class ID | Semantic Meaning | Functional Impact | Standardized Color || \------ | \------ | \------ | \------ || 0 | Empty | No gameplay surface; ignored by logic. | Black || 1 | Solid | Collision/filled region; blockers. | White (Interior) || 2 | Path | Traversable lane or tunnel for movement. | Grey || 3 | Platform Top | Intentional walkable/jumpable top edges. | Blue || 4 | Hazard | Damage zones or failure areas. | **Orange** || 5 | Spawn | Entry points for players, enemies, or items. | **Green** || 6 | Goal | Endpoints, checkpoints, or finish lines. | **Magenta** || 7 | Pickup | Collectible or interactive seed points. | Yellow || 8 | Tracking | Active vision-tracking zones. | White (Boundary) || 9 | Disabled | Inactive or "Grayed out" regions; UI safe zones. | Gray |  
The pipeline utilizes two methods for generating these maps:

* **Procedural Adapters:**  Prioritized for stability. For a  **Maze Game** , the adapter performs path graph extraction; for a  **Platformer** , it handles top-edge detection and underside culling.  
* **Manual Overlays:**  Used for creative intent when algorithms fail. Examples include authoring  **bespoke one-way gates**  in a racer or  **secret tunnels**  that break standard pathfinding logic.This data model ensures that the software stack can process physical environments into actionable game data with minimal manual intervention.

#### 4\. Technical Stack & Software Architecture

The platform utilizes a "Hybrid Stack" approach, combining high-level game engine capabilities with the precision of industrial computer vision.

* **Godot 4.x (The Hub/Runtime):**  The primary hub for the Operator UI and runtime. Godot 4.5+ utilizes  **SDL 3** , providing robust, normalized support for diverse game controllers. It manages multi-window/full-screen workflows and the loading of external resource packs.  
* **OpenCV (The Vision Engine):**  Responsible for the "heavy lifting" of spatial alignment, including perspective correction (homography), ArUco marker detection, and high-precision ChArUco calibration.

##### Software Comparison

Stack,Strengths,Use Case  
Godot 4.x,"Export system, UI workflow, SDL 3 input, runtime pack loading.",Primary Hub & Runtime UI  
OpenCV,"Professional-grade calibration, ArUco, and warping.",Calibration & Arena Mapping  
Python,Rapid R\&D loop and computer vision scripting.,Internal Tools/Prototypes  
raylib,Efficient for low-power ARM fallback.,Future Optimization Path  
Godot is the superior choice for a public-facing runtime because it allows games to be hot-loaded as isolated modules, ensuring the core "Arena Hub" remains stable even if a specific cartridge encounters an error.

#### 5\. Hardware Specification & Environmental Strategy

Hardware selection focuses on minimizing "venue friction"—the time required to set up in unpredictable environments.

##### Hardware Profiles

* **Profile L (Laptop MVP):**  Standard x86 Windows/Linux laptops. Targets 1080p @ 60 fps with a relaxed shader budget for development and high-end installations.  
* **Profile P (Raspberry Pi 5 Portable):**  The primary appliance-grade target.  
* **CPU:**  Cortex-A76 @ 2.4GHz.  
* **GPU:**  Vulkan/OpenGL ES support for modern rendering.  
* **Power:**  Requires a stable 5A power supply.  
* **Cooling:**  Active cooling is mandatory to maintain 720p @ 60 fps without thermal throttling.

##### Projection & Peripherals

The platform standardizes on  **Short-Throw Projection** . These units provide a large image at a short distance, significantly reducing shadows cast by players and eye glare. We avoid Ultra-Short-Throw (UST) for the portable kit as UST is highly sensitive to small physical movements, making calibration brittle.Peripherals must be  **XInput-compatible**  (Xbox, 8BitDo). By normalizing input at the engine level through SDL 3, the platform remains resilient against hardware variations.

##### Visual Direction & Operator UX

The Hub interface follows a "Nintendo meets Blackmagic Design" philosophy. It avoids "Gamer RGB" or "Cyberpunk" aesthetics in favor of a  **modernist wayfinding system** :

* **Palette:**  Dark backgrounds with high-contrast semantic colors (Cyan, Orange, Magenta).  
* **Controls:**  Large, touch-friendly geometry designed for outdoor use at night.  
* **Clutter:**  Minimalist layout that prioritizes the "Arena View" as the hero object.

#### 6\. Calibration Workflow & Physical Alignment

To maintain image integrity, we adhere to a strict placement hierarchy:  **Optical placement first, software mapping second, and in-projector digital keystone last.**

##### The Calibration Roadmap

1. **Manual Four-Point Homography:**  The baseline phase. Operators map the four corners of the projected image to the physical arena plane. Sufficient for basic flat surfaces.  
2. **Camera-Assisted ChArUco Recalibration:**  The high-precision wizard flow. By placing a ChArUco board in the space, the system uses a camera to automatically calculate sub-pixel alignment, which is critical for high-precision venue recall.  
3. **Structured-Light Calibration:**  A late-stage R\&D goal for automated multi-projector registration and non-planar geometry.

##### Operator UX Safety

Reliability in public installations is ensured via:

* **Panic Black Button:**  Instantly kills all projection output.  
* **Last-Known-Good Restore:**  A one-click recovery for accidental hardware shifts.  
* **Test Pattern Mode:**  High-contrast grids for verifying corner-to-corner accuracy.

#### 7\. Deployment, Packaging, and "Cartridge" Integration

Games are deployed as "Cartridges" using Godot’s .pck resource pack loading mechanism (ProjectSettings.load\_resource\_pack()). This keeps the core executable stable while content is updated.

##### Directory Structure

* /cartridges/: Contains the .pck game files and manifests.  
* /scenes/: Stores venue-specific calibration and override.cfg files.  
* /logs/: Performance and error tracking.Site-specific overrides (like a unique resolution or venue-specific controller remapping) are handled via  **override.cfg** , ensuring the base game logic remains untouched.

##### Sample Cartridge Manifest (YAML)

id: "pixel-runner-v1"  
name: "Pixel Runner"  
version: "1.0.4"  
requirements:  
  semantics: \[path, platform\_top, hazard, goal\]  
  players: 1-2  
  min\_specs: "profile\_p"  
assets:  
  pack\_path: "res://cartridges/pixel\_runner.pck"

#### 8\. QA Framework & Performance Benchmarks

Stability is maintained through "Golden-Image Tests"—verifying that map conversions (like path graph extraction) remain consistent across development cycles.

##### Venue Acceptance Script

Operators follow this step-by-step checklist to verify site integrity:

1. **Power Cycle:**  Confirm all peripherals and the compute unit boot correctly.  
2. **Restore Last-Known-Good:**  Load the saved scene and verify physical alignment.  
3. **Optical Check:**  Project a test pattern; ensure corner-to-corner focus.  
4. **Cartridge Stress Test:**  Launch three different Cartridges and verify controller responsiveness.  
5. **Recovery Test:**  Trigger "Panic Black" and restore output to confirm system resilience.

##### Success Criteria

Metric,Target Goal  
First-time Venue Setup,\< 15 Minutes  
Returning Scene Load,\< 2 Minutes  
Level Swap Latency,\< 10 Seconds  
Game Launch Latency,\< 5 Seconds  
Frame Rate Stability,Stable 60 fps (Profile L & P)  
This specification serves as the definitive blueprint for the Arena Abstraction Platform, providing a scalable foundation for turning any physical space into a reliable, interactive digital arena.  
