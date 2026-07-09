package com.aberp.rostering.chat.factory;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.rostering.chat.process.CloseRosteringChat;
import com.aberp.rostering.chat.process.SendRosteringReply;

public class RosteringChatProcessFactory implements IProcessFactory {
	@Override
	public ProcessCall newProcessInstance(String className) {
		if (SendRosteringReply.class.getName().equals(className)) {
			return new SendRosteringReply();
		}
		if (CloseRosteringChat.class.getName().equals(className)) {
			return new CloseRosteringChat();
		}
		return null;
	}
}
