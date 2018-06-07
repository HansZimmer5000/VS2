package mware_lib;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.Socket;
import java.util.Arrays;

public class SkeletonThread extends Thread {

	private Socket cSocket;
	private BufferedReader in;
	private BufferedWriter out;
	private Object servant;

	public SkeletonThread(Socket clientSocket, Object servant) throws IOException {
		this.cSocket = clientSocket;
		this.servant = servant;
		System.out.println("Client hat sich angemeldet " + servant.getClass().getPackage());
	}

	@Override
	public void run() {
		String msgFromClient;
		//while (!this.isInterrupted()) {
			try {
				this.in = new BufferedReader(new InputStreamReader(cSocket.getInputStream()));
				this.out = new BufferedWriter(new OutputStreamWriter(cSocket.getOutputStream()));
				System.out.println("waiting for input");
				System.out.println(cSocket.isConnected());
				msgFromClient = in.readLine();
				if (msgFromClient != null) {
					System.out.println("Nachricht vom Client erhalten: " + msgFromClient);

					try {
						// Oder mit Reflection (oder ohne) in Server Klasse
						Message message = new Message(msgFromClient);

						System.out.println("Reflecting: " + servant.getClass() + " " + message.getMethodName());
						Method method = servant.getClass().getMethod(message.getMethodName(), message.getParameterClasses());
						Object returnValue = method.invoke(servant, message.getParameterValues());
						out.write(returnValue + "\n");
						out.flush();

					} catch (NoSuchMethodException | SecurityException | IllegalAccessException
							| IllegalArgumentException | InvocationTargetException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}

				}

			} catch (IOException e) {
				System.out.println(cSocket.getInetAddress() + " disconected!");
			}
		//}
		System.out.println("Done");
	}
}
