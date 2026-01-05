package bot

import (
	"github.com/automuteus/automuteus/v8/pkg/amongus"
)

func (dgs *GameState) ResolveLinkedPlayer(userData UserData) (amongus.PlayerData, bool) {
	if userData.PlayerColor != nil {
		if player, found := dgs.GameData.GetByColorInt(*userData.PlayerColor); found {
			return player, true
		}
	}

	if userData.IsLinked() {
		if player, found := dgs.GameData.GetByName(userData.InGameName); found {
			return player, true
		}
	}

	return amongus.UnlinkedPlayer, false
}




