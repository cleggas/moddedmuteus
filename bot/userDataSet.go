package bot

import (
	"fmt"
	"github.com/automuteus/automuteus/v8/pkg/amongus"
	"strings"
)

type UserDataSet map[string]UserData

func (dgs *GameState) GetCountLinked() int {
	LinkedPlayerCount := 0

	for _, v := range dgs.UserData {
		if v.IsLinked() {
			LinkedPlayerCount++
		}
	}
	return LinkedPlayerCount
}

func (dgs *GameState) AttemptPairingByMatchingNames(data amongus.PlayerData) string {
	name := strings.ReplaceAll(strings.ToLower(data.Name), " ", "")
	for userID, v := range dgs.UserData {
		if strings.ReplaceAll(strings.ToLower(v.GetUserName()), " ", "") == name || strings.ReplaceAll(strings.ToLower(v.GetNickName()), " ", "") == name {
			v.Link(data)
			dgs.UserData[userID] = v
			return userID
		}
	}
	return ""
}

func (dgs *GameState) UpdateUserData(userID string, data UserData) {
	if dgs.UserData != nil {
		dgs.UserData[userID] = data
	}
}

func (dgs *GameState) AttemptPairingByUserIDs(data amongus.PlayerData, userIDs map[string]interface{}) string {
	for userID := range userIDs {
		if v, ok := dgs.UserData[userID]; ok {
			if !v.IsLinked() {
				v.Link(data)
				dgs.UserData[userID] = v
			}
			return userID
		}
	}
	return ""
}

func (dgs *GameState) ClearPlayerData(userID string) bool {
	if v, ok := dgs.UserData[userID]; ok {
		v.Unlink()
		dgs.UserData[userID] = v
		return true
	}
	return false
}

func (dgs *GameState) ClearPlayerDataByPlayerName(playerName string) {
	for i, v := range dgs.UserData {
		if v.GetPlayerName() == playerName {
			v.Unlink()
			dgs.UserData[i] = v
			return
		}
	}
}

func (dgs *GameState) UnlinkAllUsers() {
	for i, v := range dgs.UserData {
		v.Unlink()
		dgs.UserData[i] = v
	}
}

func (dgs *GameState) GetUser(userID string) (UserData, error) {
	if v, ok := dgs.UserData[userID]; ok {
		return v, nil
	}
	return UserData{}, fmt.Errorf("no User found with ID %s", userID)
}

func (dgs *GameState) UpdateLinkedUserColor(playerName string, newColor int) {
	for i, v := range dgs.UserData {
		if v.GetPlayerName() == playerName {
			v.PlayerColor = &newColor
			dgs.UserData[i] = v
			return
		}
	}
}
