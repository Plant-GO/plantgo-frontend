package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins in development
	},
}

// Message types for communication
type FrameMessage struct {
	Type      string `json:"type"`
	Frame     string `json:"frame"`
	SessionID string `json:"sessionId"`
	Timestamp int64  `json:"timestamp"`
}

type PlantResult struct {
	Type       string  `json:"type"`
	PlantName  string  `json:"plantName"`
	Confidence float64 `json:"confidence"`
	SessionID  string  `json:"sessionId"`
}

type ProgressMessage struct {
	Type       string  `json:"type"`
	Confidence float64 `json:"confidence"`
	SessionID  string  `json:"sessionId"`
}

// Riddle structures
type Riddle struct {
	ID                  string    `json:"id"`
	LevelIndex          int       `json:"levelIndex"`
	RiddleText          string    `json:"riddleText"`
	PlantScientificName string    `json:"plantScientificName"`
	PlantCommonName     string    `json:"plantCommonName"`
	Hint                *string   `json:"hint,omitempty"`
	ImageURL            *string   `json:"imageUrl,omitempty"`
	IsActive            bool      `json:"isActive"`
	CreatedAt           time.Time `json:"createdAt"`
	UpdatedAt           time.Time `json:"updatedAt"`
}

// Mock plant database for testing
var mockPlants = []string{
	"Monstera Deliciosa",
	"Peace Lily",
	"Snake Plant",
	"Fiddle Leaf Fig",
	"Pothos",
	"Rubber Plant",
	"ZZ Plant",
	"Philodendron",
	"Spider Plant",
	"Aloe Vera",
}

// Mock riddle database
var mockRiddles = []Riddle{
	{
		ID:                  "riddle_1",
		LevelIndex:          0,
		RiddleText:          "I'm a tropical beauty with split leaves that resemble Swiss cheese. My large, glossy foliage can grow quite massive indoors. What am I?",
		PlantScientificName: "Monstera deliciosa",
		PlantCommonName:     "Swiss Cheese Plant",
		Hint:                stringPtr("Look for the characteristic holes and splits in my leaves!"),
		IsActive:            true,
		CreatedAt:           time.Now().AddDate(0, 0, -7),
		UpdatedAt:           time.Now().AddDate(0, 0, -1),
	},
	{
		ID:                  "riddle_2",
		LevelIndex:          1,
		RiddleText:          "I'm known for my elegant white flowers that look like flags of surrender. I can purify your air and I love humidity. What am I?",
		PlantScientificName: "Spathiphyllum wallisii",
		PlantCommonName:     "Peace Lily",
		Hint:                stringPtr("My white flowers are actually modified leaves called spathes!"),
		IsActive:            true,
		CreatedAt:           time.Now().AddDate(0, 0, -5),
		UpdatedAt:           time.Now().AddDate(0, 0, -1),
	},
	{
		ID:                  "riddle_3",
		LevelIndex:          2,
		RiddleText:          "I'm virtually indestructible with thick, upright leaves that have yellow edges. I can survive neglect and low light. What am I?",
		PlantScientificName: "Sansevieria trifasciata",
		PlantCommonName:     "Snake Plant",
		Hint:                stringPtr("I'm also called Mother-in-Law's Tongue for my sharp appearance!"),
		IsActive:            true,
		CreatedAt:           time.Now().AddDate(0, 0, -3),
		UpdatedAt:           time.Now().AddDate(0, 0, -1),
	},
	{
		ID:                  "riddle_4",
		LevelIndex:          3,
		RiddleText:          "I have large, violin-shaped leaves and I'm quite finicky about my environment. I prefer bright, indirect light and consistent care. What am I?",
		PlantScientificName: "Ficus lyrata",
		PlantCommonName:     "Fiddle Leaf Fig",
		Hint:                stringPtr("My leaves really do look like the musical instrument I'm named after!"),
		IsActive:            true,
		CreatedAt:           time.Now().AddDate(0, 0, -2),
		UpdatedAt:           time.Now().AddDate(0, 0, -1),
	},
}

// Helper function to create string pointer
func stringPtr(s string) *string {
	return &s
}

func processPlantFrame(frameData string, sessionID string) *PlantResult {
	// Simulate AI processing time
	time.Sleep(time.Millisecond * 100)

	// Generate random plant identification for demo
	plantIndex := rand.Intn(len(mockPlants))
	confidence := 0.6 + rand.Float64()*0.4 // Random confidence between 0.6-1.0

	return &PlantResult{
		Type:       "plant_identified",
		PlantName:  mockPlants[plantIndex],
		Confidence: confidence,
		SessionID:  sessionID,
	}
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Print("upgrade failed: ", err)
		return
	}
	defer conn.Close()

	log.Println("New WebSocket connection established")

	// Track session progress
	progressCount := 0

	for {
		// Read message from client
		_, messageBytes, err := conn.ReadMessage()
		if err != nil {
			log.Println("read error:", err)
			break
		}

		var frameMessage FrameMessage
		err = json.Unmarshal(messageBytes, &frameMessage)
		if err != nil {
			log.Println("json unmarshal error:", err)
			continue
		}

		if frameMessage.Type == "video_frame" {
			progressCount++

			// Send progress updates every few frames
			if progressCount%3 == 0 {
				progressMsg := ProgressMessage{
					Type:       "scanning_progress",
					Confidence: float64(progressCount) * 0.1,
					SessionID:  frameMessage.SessionID,
				}

				err = conn.WriteJSON(progressMsg)
				if err != nil {
					log.Println("write progress error:", err)
					break
				}
			}

			// After receiving several frames, identify the plant
			if progressCount >= 8 {
				result := processPlantFrame(frameMessage.Frame, frameMessage.SessionID)

				err = conn.WriteJSON(result)
				if err != nil {
					log.Println("write result error:", err)
					break
				}

				// Reset for next scan
				progressCount = 0
			}
		}
	}

	log.Println("WebSocket connection closed")
}

func enableCORS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	enableCORS(w, r)
	if r.Method == "OPTIONS" {
		return
	}

	response := map[string]string{
		"status":  "healthy",
		"service": "PlantGo Scanner Backend",
		"version": "1.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Riddle API endpoints
func getAllRiddles(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "GET" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	json.NewEncoder(w).Encode(mockRiddles)
}

func getRiddleByLevel(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "GET" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	// Extract level from URL path
	path := r.URL.Path
	levelStr := path[len("/riddles/level/"):]

	var levelIndex int
	if _, err := fmt.Sscanf(levelStr, "%d", &levelIndex); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid level index"})
		return
	}

	// Find riddle by level
	for _, riddle := range mockRiddles {
		if riddle.LevelIndex == levelIndex {
			json.NewEncoder(w).Encode(riddle)
			return
		}
	}

	w.WriteHeader(http.StatusNotFound)
	json.NewEncoder(w).Encode(map[string]string{"error": "Riddle not found for this level"})
}

func getActiveRiddles(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "GET" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var activeRiddles []Riddle
	for _, riddle := range mockRiddles {
		if riddle.IsActive {
			activeRiddles = append(activeRiddles, riddle)
		}
	}

	json.NewEncoder(w).Encode(activeRiddles)
}

func main() {
	// Seed random number generator
	rand.Seed(time.Now().UnixNano())

	// WebSocket endpoint
	http.HandleFunc("/ws", handleWebSocket)

	// Health check endpoint
	http.HandleFunc("/health", healthCheck)

	// Riddle API endpoints
	http.HandleFunc("/riddles", getAllRiddles)
	http.HandleFunc("/riddles/level/", getRiddleByLevel)
	http.HandleFunc("/riddles/active", getActiveRiddles)

	// Serve static files if needed
	http.Handle("/", http.FileServer(http.Dir("./static/")))

	log.Println("Starting PlantGo WebSocket server on :8080")
	log.Println("WebSocket endpoint: ws://localhost:8080/ws")
	log.Println("Health check: http://localhost:8080/health")
	log.Println("Riddle API: http://localhost:8080/riddles")
	log.Println("Active Riddles: http://localhost:8080/riddles/active")

	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("Server failed to start:", err)
	}
}
