import React, { useState, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Upload, FileText, CheckCircle, AlertCircle, ArrowLeft } from 'lucide-react';
import { useDropzone } from 'react-dropzone';
import axios from 'axios';
import toast from 'react-hot-toast';

const CSRProcessor = () => {
  const [uploadedFile, setUploadedFile] = useState(null);
  const [certType, setCertType] = useState('server');
  const [processing, setProcessing] = useState(false);
  const [result, setResult] = useState(null);

  const onDrop = useCallback((acceptedFiles) => {
    const file = acceptedFiles[0];
    if (file) {
      setUploadedFile(file);
      setResult(null);
    }
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/pkcs10': ['.csr'],
      'application/x-pem-file': ['.pem'],
      'text/plain': ['.csr', '.pem']
    },
    maxFiles: 1,
    maxSize: 10 * 1024 * 1024 // 10MB
  });

  const processCSR = async () => {
    if (!uploadedFile) {
      toast.error('Please select a CSR file first');
      return;
    }

    setProcessing(true);
    setResult(null);

    try {
      const formData = new FormData();
      formData.append('csr', uploadedFile);
      formData.append('type', certType);

      const response = await axios.post('/api/csr/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });

      if (response.data.success) {
        setResult({ success: true, data: response.data });
        toast.success('CSR processed successfully!');
      } else {
        setResult({ success: false, error: response.data.error });
        toast.error('Failed to process CSR');
      }
    } catch (error) {
      const errorMessage = error.response?.data?.error || 'Failed to process CSR';
      setResult({ success: false, error: errorMessage });
      toast.error(errorMessage);
    } finally {
      setProcessing(false);
    }
  };

  const resetForm = () => {
    setUploadedFile(null);
    setResult(null);
    setCertType('server');
  };

  return (
    <div className="space-y-6">
      {/* Back to Dashboard Button */}
      <div className="flex items-center">
        <Link
          to="/"
          className="flex items-center px-3 py-2 text-sm text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
        >
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Dashboard
        </Link>
      </div>

      <div>
        <h1 className="text-2xl font-bold text-gray-900">CSR Processing</h1>
        <p className="text-gray-600">Upload and sign Certificate Signing Requests</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        {/* File Upload */}
        <div className="mb-8">
          <label className="block text-sm font-medium text-gray-700 mb-4">
            Upload Certificate Signing Request (CSR)
          </label>
          
          <div
            {...getRootProps()}
            className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
              isDragActive
                ? 'border-blue-400 bg-blue-50'
                : uploadedFile
                ? 'border-green-400 bg-green-50'
                : 'border-gray-300 hover:border-gray-400'
            }`}
          >
            <input {...getInputProps()} />
            
            {uploadedFile ? (
              <div className="flex flex-col items-center">
                <CheckCircle className="h-12 w-12 text-green-500 mb-4" />
                <p className="text-lg font-medium text-green-700 mb-2">File Selected</p>
                <p className="text-sm text-green-600">{uploadedFile.name}</p>
                <p className="text-xs text-gray-500 mt-1">
                  {(uploadedFile.size / 1024).toFixed(1)} KB
                </p>
              </div>
            ) : (
              <div className="flex flex-col items-center">
                <Upload className="h-12 w-12 text-gray-400 mb-4" />
                <p className="text-lg font-medium text-gray-900 mb-2">
                  {isDragActive ? 'Drop the CSR file here' : 'Drop CSR file here or click to browse'}
                </p>
                <p className="text-sm text-gray-600">
                  Supports .csr and .pem files (max 10MB)
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Certificate Type Selection */}
        {uploadedFile && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            className="mb-8"
          >
            <label className="block text-sm font-medium text-gray-700 mb-4">
              Certificate Type
            </label>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <button
                type="button"
                onClick={() => setCertType('server')}
                className={`p-4 border-2 rounded-lg text-left transition-colors ${
                  certType === 'server'
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center mb-2">
                  <FileText className={`h-5 w-5 mr-2 ${
                    certType === 'server' ? 'text-blue-600' : 'text-gray-400'
                  }`} />
                  <span className={`font-medium ${
                    certType === 'server' ? 'text-blue-900' : 'text-gray-900'
                  }`}>
                    Server Certificate
                  </span>
                </div>
                <p className={`text-sm ${
                  certType === 'server' ? 'text-blue-700' : 'text-gray-600'
                }`}>
                  For web servers, VPN servers, and other services
                </p>
              </button>

              <button
                type="button"
                onClick={() => setCertType('client')}
                className={`p-4 border-2 rounded-lg text-left transition-colors ${
                  certType === 'client'
                    ? 'border-green-500 bg-green-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center mb-2">
                  <FileText className={`h-5 w-5 mr-2 ${
                    certType === 'client' ? 'text-green-600' : 'text-gray-400'
                  }`} />
                  <span className={`font-medium ${
                    certType === 'client' ? 'text-green-900' : 'text-gray-900'
                  }`}>
                    Client Certificate
                  </span>
                </div>
                <p className={`text-sm ${
                  certType === 'client' ? 'text-green-700' : 'text-gray-600'
                }`}>
                  For users, devices, and client applications
                </p>
              </button>
            </div>
          </motion.div>
        )}

        {/* Action Buttons */}
        {uploadedFile && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            className="flex space-x-4"
          >
            <button
              onClick={processCSR}
              disabled={processing}
              className="flex-1 bg-blue-600 text-white py-3 px-6 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {processing ? 'Processing CSR...' : 'Sign Certificate'}
            </button>
            <button
              onClick={resetForm}
              disabled={processing}
              className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Reset
            </button>
          </motion.div>
        )}

        {/* Result */}
        {result && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className={`mt-6 p-4 rounded-lg border ${
              result.success
                ? 'bg-green-50 border-green-200'
                : 'bg-red-50 border-red-200'
            }`}
          >
            <div className="flex items-start">
              {result.success ? (
                <CheckCircle className="h-6 w-6 text-green-500 mr-3 mt-0.5" />
              ) : (
                <AlertCircle className="h-6 w-6 text-red-500 mr-3 mt-0.5" />
              )}
              <div className="flex-1">
                <h4 className={`font-medium mb-2 ${
                  result.success ? 'text-green-800' : 'text-red-800'
                }`}>
                  {result.success ? 'Certificate Signed Successfully' : 'Processing Failed'}
                </h4>
                <p className={`text-sm ${
                  result.success ? 'text-green-700' : 'text-red-700'
                }`}>
                  {result.success 
                    ? 'The certificate has been signed and is ready for use. You can download it from the certificates list.'
                    : result.error || 'An unknown error occurred while processing the CSR.'
                  }
                </p>
              </div>
            </div>
          </motion.div>
        )}

        {/* Information */}
        <div className="mt-8 p-4 bg-gray-50 border border-gray-200 rounded-lg">
          <h4 className="font-medium text-gray-800 mb-2">How CSR Processing Works</h4>
          <ul className="text-sm text-gray-600 space-y-1">
            <li>• Upload a Certificate Signing Request (.csr or .pem file)</li>
            <li>• Select whether this is for a server or client certificate</li>
            <li>• Our Certificate Authority will sign the request</li>
            <li>• The signed certificate will be available for download</li>
            <li>• All processed requests are logged for audit purposes</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default CSRProcessor;