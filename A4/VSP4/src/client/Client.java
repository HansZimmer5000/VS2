package client;

import java.io.IOException;

import math_ops._CalculatorImplBase;
import mware_lib.ObjectBroker;

public class Client {

	public static void main(String[] args) throws IOException  {

		ObjectBroker objBroker = ObjectBroker.init("", 55555, false);
		mware_lib.INameService nameSvc = objBroker.getNameService();

		System.out.println("NS-Referenz erhalten!");
		Object rawObjRef = nameSvc.resolve("zumsel");
		_CalculatorImplBase remoteObj = _CalculatorImplBase.narrowCast(rawObjRef);

		System.out.println("Methodenaufruf wird initiiert");
		double calcNum = remoteObj.add(20d,30d);
		System.out.println("Rechnung wurde durchgeführt das Ergebnis ist: " + calcNum);

		objBroker.shutDown();
	
		
	}

}
