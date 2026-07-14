package com.aberp.invoicecapture.factory;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.invoicecapture.process.ProcessInvoiceCaptureBatch;
import com.aberp.invoicecapture.process.ProcessSelectedInvoice;
import com.aberp.invoicecapture.process.UploadInvoicePdf;

public class InvoiceCaptureProcessFactory implements IProcessFactory {
	@Override
	public ProcessCall newProcessInstance(String className) {
		if (ProcessSelectedInvoice.class.getName().equals(className)) {
			return new ProcessSelectedInvoice();
		}
		if (ProcessInvoiceCaptureBatch.class.getName().equals(className)) {
			return new ProcessInvoiceCaptureBatch();
		}
		if (UploadInvoicePdf.class.getName().equals(className)) {
			return new UploadInvoicePdf();
		}
		return null;
	}
}
