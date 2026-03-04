# Project Structure - Shiny-IT Dashboard

This document describes the architecture and design of the **Shiny-IT** application, a dashboard built with R and the `bs4Dash` framework.

## 🏗️ Design Philosophy
The application follows a **modular design pattern**. Instead of a monolithic `ui.R` and `server.R`, the interface and logic are split into independent components and domain-specific modules. This ensures:
- **Maintainability:** Easier to locate and fix bugs in specific sections.
- **Scalability:** New features (axes/eixos) can be added by creating new component folders.
- **Readability:** Individual files are kept small and focused.

---

## 📂 Folder Structure

### 1. Root Directory (Core Files)
- **`app.R`**: The entry point. It orchestrates the loading of all components and launches the Shiny application.
- **`global.R`**: Contains environment-wide settings. It loads necessary libraries and reads the datasets (`data_ti.gpkg`, `estatisticas_ibge.csv`) into memory so they are available to all modules.
- **`ui.R`**: Defines the high-level layout using `bs4Dash`. It sources UI components (header, sidebar, body, footer) to assemble the main dashboard page.
- **`server.R`**: The main server function. It acts as a router, calling the server logic functions defined in the specific modules.

### 2. Layout Components (`components/`)
These files define the persistent structural elements of the dashboard:
- **`header.R`**: Top navigation bar.
- **`sidebar.R`**: Left navigation menu, defining the tabs (Eixo-1, Eixo-2).
- **`footer.R`**: Bottom information bar.
- **`body.R`**: The main content area. It acts as a container that sources and includes the content from specific modules based on the active tab.

### 3. Feature Modules
The application is organized into "Eixos" (Axes), each representing a specific analytical domain.

#### **`it-components/` (Eixo-1: Intensidade Tecnológica)**
Focuses on the spatial distribution of knowledge-intensive sectors.
- **`it_body.R`**: Defines the UI for this tab, including filters and the Leaflet map container.
- **`it_server.R`**: Contains the logic for filtering data and rendering the interactive map.
- **`it_functions.R`**: (If present) Utility functions specific to Eixo-1 calculations.

#### **`eixo2-components/` (Eixo-2: Indicadores Econômicos)**
Focuses on historical economic data and time-series analysis.
- **`eixo2_body.R`**: Defines the UI for this tab, including municipality selection and Plotly chart containers.
- **`eixo2_server.R`**: Contains the logic for dynamic UI updates (e.g., updating municipality lists based on UF) and rendering charts.
- **`eixo2_functions.R`**: Utility functions specific to Eixo-2 data processing.

---

## 🔄 Module Relationships & Data Flow

1.  **Initialization**: `app.R` calls `global.R` to load data.
2.  **UI Assembly**: `ui.R` builds the shell. `body.R` imports the `it_tab_content()` and `eixo2_tab_content()` functions from their respective folders to populate the tabs.
3.  **Server Logic Delegation**: When the app runs, `server.R` executes:
    - `empresas_server_logic()`: Handles reactivity for Eixo-1.
    - `eixo2_server_logic()`: Handles reactivity for Eixo-2.
4.  **Reactivity**:
    - User input in `it_body.R` (e.g., category selection) triggers observers in `it_server.R`.
    - User input in `eixo2_body.R` (e.g., UF selection) triggers observers in `eixo2_server.R` to update municipality choices and charts.

---

## 🛠️ Technology Stack
- **UI Framework**: `bs4Dash` (Bootstrap 4 for Shiny).
- **Interactive Maps**: `leaflet`.
- **Interactive Charts**: `plotly`.
- **Data Handling**: `sf` (spatial data), `dplyr`, `readr`.
- **UX Enhancements**: `shinycssloaders` for loading states.
