package station;

import static org.junit.Assert.*;

import java.util.Arrays;

import org.junit.Test;

import station.Message;

public class MessageTests {

	
	@Test
	public void test_createIncompleteMessage_1() {
		String isResult;
		String expectedResult;
		
		expectedResult = "A-team-4711-4";
		isResult = Message.createIncompleteMessage("A", "-team-4711-", 4).toString();
		assertEquals(expectedResult, isResult);
	}
	
	@Test
	public void test_createMessageFromByte_1() {
		String isResult;
		String expectedResult;
		byte[] messageInByte;

		expectedResult = "A-team-4711-123456789012-477394825";
		messageInByte = new byte[] {65, 
									45, 116, 101, 97, 109, 45, 52, 55, 49, 49, 45, 
									49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 49, 50, 45,
									4,
									55, 55, 51, 57, 52, 56, 50, 53};
		isResult = Message.createMessageFromByte(messageInByte, 77394825).toString();
		assertEquals(expectedResult, isResult);
	}
	
	@Test
	public void test_createMessageFromByte_2() {
		String isResult;
		String expectedResult;
		byte[] messageInByte;
		
		expectedResult = "A-team-4711-123456789012-2577394825";
		messageInByte = new byte[] {65, 
									45, 116, 101, 97, 109, 45, 52, 55, 49, 49, 45, 
									49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 49, 50, 45,
									25,
									55, 55, 51, 57, 52, 56, 50, 53};
		isResult = Message.createMessageFromByte(messageInByte, 0).toString();
		assertEquals(expectedResult, isResult);
	}
	
	
	@Test
	public void test_getStationType_1(){
		fail("Not implemented yet");
	}
	
	@Test
	public void test_getStationName_1(){
		fail("Not implemented yet");
	}
	
	@Test
	public void test_getSlotNumber_1(){
		int isResult;
		int expectedResult;
		Message message;
		
		message = Message.createIncompleteMessage("A","-team-4711-", 4);
		expectedResult = 4;
		isResult = message.getSlotNumber();
		assertEquals(expectedResult, isResult);		
	}
	
	@Test
	public void test_getSlotNumber_2(){
		int isResult;
		int expectedResult;
		Message message;
		
		message = Message.createIncompleteMessage("A","-team-4711-", 25);
		expectedResult = 25;
		isResult = message.getSlotNumber();
		assertEquals(expectedResult, isResult);		
	}
	
	
	@Test
	public void test_getReceivedTime_1(){
		fail("Not implemented yet");
	}
	
	@Test
	public void test_getSendTime_1(){
		fail("Not implemented yet");
	}
	
	@Test
	public void test_setSendtime_1(){
		fail("Not implemented yet");
	}
	
	@Test
	public void test_prepareForSending_1() {
		byte[] isResult;
		byte[] expectedResult;
		Message message;
		
		message = Message.createIncompleteMessage("A","-team-4711-",4);
		expectedResult = new byte[] {65, 
									45, 116, 101, 97, 109, 45, 52, 55, 49, 49, 45, 
									4,
									55, 55, 51, 57, 52, 56, 50, 53};
		isResult = message.prepareForSending(77394825);
		assertArrayEquals(expectedResult, isResult);
	}
	
	@Test
	public void test_toString_1(){
		fail("Not implemented yet");
	}
	
	@Test
	public void test_toByteArray_1(){
		fail("Not implemented yet");
	}
	
	@Test
	public void test_unifyArrays_1(){
		fail("Not implemented yet");
	}
}
