package rspam

import "fmt"

type SymbolData struct {
	Name        string  `json:"name"`
	Score       float64 `json:"score"`
	MetricScore float64 `json:"metric_score"`
	Description string  `json:"description"`
}

type RspamResponse struct {
	Score         float64               `json:"score"`
	RequiredScore float64               `json:"required_score"`
	Action        string                `json:"action"`
	MessageID     string                `json:"message-id"`
	Symbols       map[string]SymbolData `json:"symbols"`
}

func (s RspamResponse) String() string {
	return fmt.Sprintf("Score: %v, RequiredScore: %v, Action: %v, MessageID: %v", s.Score, s.RequiredScore, s.Action, s.MessageID)
}
