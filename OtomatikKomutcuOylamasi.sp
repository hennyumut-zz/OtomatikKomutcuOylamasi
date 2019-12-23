/*
 * CS:GO Otomatik Komutcu Oylamasi
 * by: Henny!
 * 
 * Copyright (C) 2016-2019 Umut 'Henny!' Uzatmaz
 *
 * This file is part of the Henny! SourceMod Plugin Package.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <warden>

int warden = -1;
int playerNumber = 0;

int yesSelected = 0;
int noSelected = 0;

ConVar voteYuzde;
Handle voteTimer = INVALID_HANDLE;

public Plugin myinfo = 
{
	name 	= "[CSGO] Otomatik Komutçu Oylaması",
	author 	= "northeaster - Fix: @KingHenny! (Oylama Sistemi: Uğur Bayraktar)",
	version = "1.0.1",
	url 	= "forum.sourceturk.net"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_gectim", wardenCheck);
	
	voteYuzde = CreateConVar("komutcu-degistir_yuzde", "0.76", "Oylamanın sonuca varması için gerekli yüzde. (0.1-1.0 arasında verin.)", _, true, 0.1, true, 1.0);
}

public Action wardenCheck(int client, int args)
{
	if (IsClientInGame(client) && warden_iswarden(client) && voteTimer == INVALID_HANDLE)
	{
		PrintToChatAll("[x05SourceTurk\x01] Süre başlatıldı! Komutçu oylaması 30 dakika sonra yapılacaktır.");
		voteTimer = CreateTimer(1800.0, VoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "[x05SourceTurk\x01] Komutçu değilsiniz veya süre zaten başlatılmış.");
		return Plugin_Handled;
	}
}

public Action VoteStart(Handle timer, any data)
{
	if (IsVoteInProgress())
	{
		return;
	}
	
	playerNumber = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		
		playerNumber++;
	}
	
	Menu menu = new Menu(VoteResult);
	menu.SetTitle("%i adlı Komutçu değiştirilsin mi?", warden);
	menu.AddItem("yes", "Evet");
	menu.AddItem("no", "Hayır");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

public int VoteResult(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_VoteEnd)
	{
		VoteCompleted();
	}
	else if (action == MenuAction_Select)
	{
		char selected[32];
		GetMenuItem(menu, param2, selected, sizeof(selected));
		
		if (StrEqual(selected, "yes", false))
		{
			yesSelected++;
		}
		else if (StrEqual(selected, "no", false))
		{
			noSelected++;
		}
		
		PrintHintTextToAll("Oylama Sonucu:\nEvet Sayısı: %d\nHayır Sayısı: %d", yesSelected, noSelected);
		
		playerNumber++;
		if (playerNumber == yesSelected + noSelected)
		{
			VoteCompleted();
			
			if (menu != INVALID_HANDLE)
			{
				CloseHandle(menu);
			}
		}
	}
}

public void VoteCompleted()
{
	char sYesSelected[10];
	char sNoSelected[10];
	float fYesSelected;
	float fNoSelected;
	float fRatio;
	float fYuzde = GetConVarFloat(voteYuzde);
	IntToString(yesSelected, sYesSelected, sizeof(sYesSelected));
	IntToString(noSelected, sNoSelected, sizeof(sNoSelected));
	fYesSelected = StringToFloat(sYesSelected);
	fNoSelected = StringToFloat(sNoSelected);
	fRatio = (fYesSelected / (fYesSelected + fNoSelected));
	fYuzde = fYuzde + 0.000001;
	
	PrintToChatAll("[x05SourceTurk\x01] Evet Sayısı: %d, Hayır sayısı: %d", yesSelected, noSelected);
	PrintToChatAll("[x05SourceTurk\x01] Oran: %.2f - Gereken: %.2f", fRatio, fYuzde);
	
	if (fRatio >= fYuzde)
	{
		PrintToChatAll("[x05SourceTurk\x01] Komutçu %i, oylama sonucunda komuttan atılmıştır.", warden);
		warden_remove(warden);
		KillTimer(voteTimer, false);
		voteTimer = INVALID_HANDLE;
	}
	else
	{
		PrintToChatAll("[x05SourceTurk\x01] Komutçu %i, oylama sonucu komutta kalmasını tercih etti.", warden);
		KillTimer(voteTimer, false);
		voteTimer = INVALID_HANDLE;
		voteTimer = CreateTimer(1800.0, VoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
