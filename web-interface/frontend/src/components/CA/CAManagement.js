import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Shield, CheckCircle, AlertCircle, Settings, Download, RefreshCw, Edit, Trash2, ArrowLeft, Home, Key, AlertTriangle } from 'lucide-react';
import { useForm } from 'react-hook-form';
import axios from 'axios';
import toast from 'react-hot-toast';

const CAManagement = () => {
  const [caStatus, setCAStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [showVarsForm, setShowVarsForm] = useState(false);
  const [varsData, setVarsData] = useState(null);
  const [updatingVars, setUpdatingVars] = useState(false);

  const { register, handleSubmit, formState: { errors }, reset } = useForm({
    defaultValues: {
      country: 'IT',
      province: 'Tuscany',
      city: 'Prato',
      org: 'MyOrganization',
      email: 'admin@example.com',
      ou: 'IT Department'
    }
  });

  const { register: registerVars, handleSubmit: handleSubmitVars, formState: { errors: errorsVars }, reset: resetVars } = useForm();

  useEffect(() => {
    fetchCAStatus();
  }, []);

  const fetchCAStatus = async () => {
    try {
      const response = await axios.get('/api/ca/status');
      setCAStatus(response.data);
      
      // If CA is active and has vars data, set it
      if (response.data.success && response.data.vars) {
        setVarsData(response.data.vars);
      }
    } catch (error) {
      toast.error('Failed to fetch CA status');
    } finally {
      setLoading(false);
    }
  };

  const fetchVarsConfig = async () => {
    try {
      const response = await axios.get('/api/config/vars');
      if (response.data.exists) {
        setVarsData(response.data.config);
        resetVars(response.data.config);
      }
    } catch (error) {
      toast.error('Failed to fetch vars configuration');
    }
  };

  const updateVars = async (data) => {
    setUpdatingVars(true);
    try {
      await axios.post('/api/config/vars', data);
      toast.success('Vars configuration updated successfully!');
      setVarsData(data);
      setShowVarsForm(false);
    } catch (error) {
      toast.error(error.response?.data?.error || 'Failed to update vars configuration');
    } finally {
      setUpdatingVars(false);
    }
  };

  const downloadCA = async () => {
    try {
      const response = await axios.get('/api/ca/download', { responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'ca.crt');
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
      toast.success('CA certificate downloaded successfully!');
    } catch (error) {
      toast.error('Failed to download CA certificate');
    }
  };

  const downloadCAPrivateKey = async () => {
    // Show critical security warning
    const confirmed = window.confirm(
      '🔴 CRITICAL SECURITY WARNING 🔴\n\n' +
      'You are about to download the CA PRIVATE KEY!\n\n' +
      'This is the MOST SENSITIVE file in your PKI:\n' +
      '• Anyone with this key can issue certificates for your CA\n' +
      '• Store it in a secure, encrypted location\n' +
      '• Never share it or store it unencrypted\n' +
      '• Consider backing it up to secure offline storage\n\n' +
      'Do you want to proceed with downloading the CA private key?'
    );

    if (!confirmed) return;

    // Second confirmation for extra security
    const doubleConfirmed = window.confirm(
      '⚠️ FINAL CONFIRMATION ⚠️\n\n' +
      'This will download ca.key - your Certificate Authority\'s private key.\n\n' +
      'Are you absolutely sure you want to continue?'
    );

    if (!doubleConfirmed) return;

    try {
      const response = await axios.get('/api/ca/download-key', { responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'ca.key');
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
      toast.success('CA private key downloaded successfully! Please store it securely.', {
        duration: 6000,
        style: {
          background: '#ef4444',
          color: 'white',
          fontWeight: 'bold'
        }
      });
    } catch (error) {
      toast.error('Failed to download CA private key');
    }
  };

  const recreateCA = () => {
    if (window.confirm('Are you sure you want to recreate the Certificate Authority? This will invalidate all existing certificates!')) {
      // Show the create CA form
      setCAStatus({ success: false });
      fetchVarsConfig(); // Load existing vars for the form
    }
  };

  const createCA = async (data) => {
    setCreating(true);
    try {
      await axios.post('/api/ca/create', data);
      toast.success('Certificate Authority created successfully!');
      fetchCAStatus();
    } catch (error) {
      toast.error(error.response?.data?.error || 'Failed to create CA');
    } finally {
      setCreating(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

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

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center">
            <Shield className="h-8 w-8 text-blue-600 mr-3" />
            <div>
              <h2 className="text-2xl font-bold text-gray-900">Certificate Authority</h2>
              <p className="text-gray-600">Manage your PKI root certificate authority</p>
            </div>
          </div>
        </div>

        {/* CA Status */}
        <div className="mb-8 p-4 bg-gray-50 rounded-lg">
          <div className="flex items-center">
            {caStatus?.success ? (
              <CheckCircle className="h-6 w-6 text-green-500 mr-3" />
            ) : (
              <AlertCircle className="h-6 w-6 text-red-500 mr-3" />
            )}
            <div>
              <h3 className="font-semibold text-gray-900">
                CA Status: {caStatus?.success ? 'Active' : 'Not Found'}
              </h3>
              <p className="text-sm text-gray-600">
                {caStatus?.success 
                  ? 'Certificate Authority is configured and ready' 
                  : 'No Certificate Authority found. Create one to start issuing certificates.'
                }
              </p>
            </div>
          </div>
        </div>

        {/* Create CA Form */}
        {!caStatus?.success && (
          <motion.form
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            onSubmit={handleSubmit(createCA)}
            className="space-y-6"
          >
            <div className="flex items-center mb-4">
              <Settings className="h-6 w-6 text-blue-600 mr-2" />
              <h3 className="text-lg font-semibold text-gray-900">Create Certificate Authority</h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Country Code
                </label>
                <input
                  type="text"
                  maxLength="2"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="IT"
                  {...register('country', { required: 'Country is required', minLength: 2, maxLength: 2 })}
                />
                {errors.country && (
                  <p className="mt-1 text-sm text-red-600">{errors.country.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Province/State
                </label>
                <input
                  type="text"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Tuscany"
                  {...register('province', { required: 'Province is required' })}
                />
                {errors.province && (
                  <p className="mt-1 text-sm text-red-600">{errors.province.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  City
                </label>
                <input
                  type="text"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Prato"
                  {...register('city', { required: 'City is required' })}
                />
                {errors.city && (
                  <p className="mt-1 text-sm text-red-600">{errors.city.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Organization
                </label>
                <input
                  type="text"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="MyOrganization"
                  {...register('org', { required: 'Organization is required' })}
                />
                {errors.org && (
                  <p className="mt-1 text-sm text-red-600">{errors.org.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Email
                </label>
                <input
                  type="email"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="admin@example.com"
                  {...register('email', { 
                    required: 'Email is required',
                    pattern: {
                      value: /^\S+@\S+$/i,
                      message: 'Invalid email address'
                    }
                  })}
                />
                {errors.email && (
                  <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Organizational Unit (Optional)
                </label>
                <input
                  type="text"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="IT Department"
                  {...register('ou')}
                />
              </div>
            </div>

            <div className="pt-4 border-t border-gray-200">
              <button
                type="submit"
                disabled={creating}
                className="w-full bg-blue-600 text-white py-3 px-6 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {creating ? 'Creating Certificate Authority...' : 'Create Certificate Authority'}
              </button>
            </div>
          </motion.form>
        )}

        {/* CA Information (if exists) */}
        {caStatus?.success && (
          <div className="space-y-4">
            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
              <h4 className="font-medium text-green-800 mb-2">Certificate Authority Active</h4>
              <p className="text-green-700 text-sm mb-4">
                Your Certificate Authority is configured and ready to issue certificates.
                You can now create server and client certificates from the navigation menu.
              </p>
              
              {/* Action Buttons */}
              <div className="flex flex-wrap gap-3">
                <button
                  onClick={downloadCA}
                  className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  <Download className="h-4 w-4 mr-2" />
                  Download CA Certificate
                </button>
                
                <button
                  onClick={downloadCAPrivateKey}
                  className="flex items-center px-4 py-2 bg-red-800 text-white rounded-lg hover:bg-red-900 transition-colors border-2 border-red-600 shadow-lg"
                  title="⚠️ CRITICAL: Downloads the CA private key - handle with extreme care!"
                >
                  <Key className="h-4 w-4 mr-2" />
                  <AlertTriangle className="h-3 w-3 mr-1 text-yellow-300" />
                  Download CA Private Key
                </button>
                
                <button
                  onClick={() => {
                    setShowVarsForm(!showVarsForm);
                    if (!showVarsForm) fetchVarsConfig();
                  }}
                  className="flex items-center px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors"
                >
                  <Edit className="h-4 w-4 mr-2" />
                  Edit Configuration
                </button>
                
                <button
                  onClick={recreateCA}
                  className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Recreate CA
                </button>
              </div>

              {/* Security Warning for Private Key */}
              <div className="mt-4 p-3 bg-red-50 border-l-4 border-red-400 rounded-r-lg">
                <div className="flex items-center">
                  <AlertTriangle className="h-5 w-5 text-red-400 mr-2 flex-shrink-0" />
                  <div>
                    <h5 className="font-medium text-red-800">Security Notice</h5>
                    <p className="text-sm text-red-700">
                      The CA private key is the most critical component of your PKI. Download and store it securely offline. 
                      Anyone with access to this key can issue certificates for your CA.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* CA Details */}
            {varsData && (
              <div className="bg-white border border-gray-200 rounded-lg p-4">
                <h4 className="font-medium text-gray-900 mb-3">Current Configuration</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="font-medium text-gray-600">Country:</span>
                    <span className="ml-2 text-gray-900">{varsData.country}</span>
                  </div>
                  <div>
                    <span className="font-medium text-gray-600">Province:</span>
                    <span className="ml-2 text-gray-900">{varsData.province}</span>
                  </div>
                  <div>
                    <span className="font-medium text-gray-600">City:</span>
                    <span className="ml-2 text-gray-900">{varsData.city}</span>
                  </div>
                  <div>
                    <span className="font-medium text-gray-600">Organization:</span>
                    <span className="ml-2 text-gray-900">{varsData.org}</span>
                  </div>
                  <div>
                    <span className="font-medium text-gray-600">Email:</span>
                    <span className="ml-2 text-gray-900">{varsData.email}</span>
                  </div>
                  <div>
                    <span className="font-medium text-gray-600">Organizational Unit:</span>
                    <span className="ml-2 text-gray-900">{varsData.ou}</span>
                  </div>
                </div>
              </div>
            )}

            {/* Vars Configuration Form */}
            {showVarsForm && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-white border border-gray-200 rounded-lg p-6"
              >
                <div className="flex items-center justify-between mb-4">
                  <h4 className="font-medium text-gray-900">Update Configuration</h4>
                  <button
                    onClick={() => setShowVarsForm(false)}
                    className="text-gray-400 hover:text-gray-600"
                  >
                    ✕
                  </button>
                </div>
                
                <form onSubmit={handleSubmitVars(updateVars)} className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Country Code</label>
                      <input
                        type="text"
                        maxLength="2"
                        className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        {...registerVars('country', { required: 'Country is required', minLength: 2, maxLength: 2 })}
                      />
                      {errorsVars.country && (
                        <p className="mt-1 text-sm text-red-600">{errorsVars.country.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Province/State</label>
                      <input
                        type="text"
                        className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        {...registerVars('province', { required: 'Province is required' })}
                      />
                      {errorsVars.province && (
                        <p className="mt-1 text-sm text-red-600">{errorsVars.province.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
                      <input
                        type="text"
                        className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        {...registerVars('city', { required: 'City is required' })}
                      />
                      {errorsVars.city && (
                        <p className="mt-1 text-sm text-red-600">{errorsVars.city.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Organization</label>
                      <input
                        type="text"
                        className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        {...registerVars('org', { required: 'Organization is required' })}
                      />
                      {errorsVars.org && (
                        <p className="mt-1 text-sm text-red-600">{errorsVars.org.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                      <input
                        type="email"
                        className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        {...registerVars('email', { 
                          required: 'Email is required',
                          pattern: { value: /^\S+@\S+$/i, message: 'Invalid email address' }
                        })}
                      />
                      {errorsVars.email && (
                        <p className="mt-1 text-sm text-red-600">{errorsVars.email.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Organizational Unit</label>
                      <input
                        type="text"
                        className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        {...registerVars('ou')}
                      />
                    </div>
                  </div>

                  <div className="flex gap-3 pt-4 border-t border-gray-200">
                    <button
                      type="submit"
                      disabled={updatingVars}
                      className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                      {updatingVars ? 'Updating...' : 'Update Configuration'}
                    </button>
                    <button
                      type="button"
                      onClick={() => setShowVarsForm(false)}
                      className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition-colors"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              </motion.div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default CAManagement;