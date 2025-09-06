import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  Shield, 
  Award, 
  AlertTriangle, 
  CheckCircle, 
  Clock,
  Users,
  Server,
  FileText,
  RefreshCw,
  TrendingUp,
  Plus,
  Settings,
  Upload
} from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import axios from 'axios';
import toast from 'react-hot-toast';

const Dashboard = () => {
  const [stats, setStats] = useState({
    ca: { status: 'unknown', created: null, expires: null },
    certificates: { total: 0, server: 0, client: 0 },
    expiring: { critical: 0, warning: 0, good: 0 },
    recent: []
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 30000); // Refresh every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const fetchDashboardData = async () => {
    try {
      const [caStatus, certificates] = await Promise.all([
        axios.get('/api/ca/status'),
        axios.get('/api/certificates')
      ]);

      // Process CA data
      const caData = caStatus.data.success ? 
        { status: 'active', ...caStatus.data } : 
        { status: 'inactive' };

      // Process certificates data
      const certsData = certificates.data.success ? certificates.data : { certificates: [] };
      const certs = certsData.certificates || [];
      
      const serverCerts = certs.filter(c => c.type === 'server').length;
      const clientCerts = certs.filter(c => c.type === 'client').length;
      
      // Categorize by expiration
      const now = new Date();
      let critical = 0, warning = 0, good = 0;
      
      certs.forEach(cert => {
        if (cert.expires) {
          const expiryDate = new Date(cert.expires);
          const daysUntilExpiry = Math.floor((expiryDate - now) / (1000 * 60 * 60 * 24));
          
          if (daysUntilExpiry < 7) critical++;
          else if (daysUntilExpiry < 30) warning++;
          else good++;
        }
      });

      setStats({
        ca: caData,
        certificates: { 
          total: certs.length, 
          server: serverCerts, 
          client: clientCerts 
        },
        expiring: { critical, warning, good },
        recent: certs.slice(-5).reverse() // Last 5 certificates
      });
      
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      toast.error('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const refreshData = () => {
    setLoading(true);
    fetchDashboardData();
  };

  // Chart data
  const expirationData = [
    { name: 'Good (>30d)', value: stats.expiring.good, color: '#10b981' },
    { name: 'Warning (7-30d)', value: stats.expiring.warning, color: '#f59e0b' },
    { name: 'Critical (<7d)', value: stats.expiring.critical, color: '#ef4444' }
  ];

  const certificateTypeData = [
    { name: 'Server', count: stats.certificates.server },
    { name: 'Client', count: stats.certificates.client }
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center mb-3">
            <div className="flex-shrink-0 mr-4">
              <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex items-center justify-center shadow-lg">
                <Award className="w-8 h-8 text-white" />
              </div>
            </div>
            <h1 className="text-3xl font-bold text-gray-900">Certificate Manager</h1>
          </div>
          <p className="text-gray-600 ml-16">Certificate Authority Overview</p>
        </div>
        <button
          onClick={refreshData}
          className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          disabled={loading}
        >
          <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Quick Actions */}
      {!stats.ca.success && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl shadow-lg p-6 text-white"
        >
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-xl font-bold mb-2">Get Started</h3>
              <p className="text-blue-100">No Certificate Authority found. Create one to start managing certificates.</p>
            </div>
            <Link
              to="/ca"
              className="bg-white text-blue-600 px-6 py-3 rounded-lg font-medium hover:bg-blue-50 transition-colors inline-flex items-center"
            >
              <Settings className="h-5 w-5 mr-2" />
              Setup CA
            </Link>
          </div>
        </motion.div>
      )}

      {/* CA Management - Always show */}
      {stats.ca.success && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-gray-500 to-gray-600 rounded-xl shadow-lg p-4 text-white mb-4"
        >
          <div className="flex items-center justify-between">
            <div>
              <h4 className="text-lg font-semibold">Certificate Authority Management</h4>
              <p className="text-gray-200 text-sm">Configure, recreate or manage your CA settings</p>
            </div>
            <Link
              to="/ca"
              className="bg-white text-gray-600 px-4 py-2 rounded-lg font-medium hover:bg-gray-50 transition-colors inline-flex items-center"
            >
              <Settings className="h-4 w-4 mr-2" />
              Manage CA
            </Link>
          </div>
        </motion.div>
      )}

      {stats.ca.success && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="grid grid-cols-1 md:grid-cols-3 gap-4"
        >
          <Link
            to="/certificates/new"
            className="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-6 text-white hover:from-green-600 hover:to-green-700 transition-all transform hover:scale-105 shadow-lg"
          >
            <div className="flex items-center">
              <div className="p-3 bg-white/20 rounded-full mr-4">
                <Plus className="h-6 w-6" />
              </div>
              <div>
                <h3 className="font-bold text-lg">New Certificate</h3>
                <p className="text-green-100 text-sm">Generate server or client cert</p>
              </div>
            </div>
          </Link>

          <Link
            to="/csr"
            className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-6 text-white hover:from-purple-600 hover:to-purple-700 transition-all transform hover:scale-105 shadow-lg"
          >
            <div className="flex items-center">
              <div className="p-3 bg-white/20 rounded-full mr-4">
                <Upload className="h-6 w-6" />
              </div>
              <div>
                <h3 className="font-bold text-lg">Sign CSR</h3>
                <p className="text-purple-100 text-sm">Upload and sign external CSR</p>
              </div>
            </div>
          </Link>

          <Link
            to="/certificates"
            className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-6 text-white hover:from-blue-600 hover:to-blue-700 transition-all transform hover:scale-105 shadow-lg"
          >
            <div className="flex items-center">
              <div className="p-3 bg-white/20 rounded-full mr-4">
                <Award className="h-6 w-6" />
              </div>
              <div>
                <h3 className="font-bold text-lg">Manage Certificates</h3>
                <p className="text-blue-100 text-sm">View and renew certificates</p>
              </div>
            </div>
          </Link>
        </motion.div>
      )}

      {/* CA Status Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <div className={`p-3 rounded-full ${
              stats.ca.status === 'active' ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'
            }`}>
              <Shield className="h-6 w-6" />
            </div>
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Certificate Authority</h3>
              <p className="text-gray-600">
                Status: <span className={`font-medium ${
                  stats.ca.status === 'active' ? 'text-green-600' : 'text-red-600'
                }`}>
                  {stats.ca.status === 'active' ? 'Active' : 'Inactive'}
                </span>
              </p>
            </div>
          </div>
          <div className="text-right">
            {stats.ca.expires && (
              <div className="mb-2">
                <p className="text-sm text-gray-500">CA Expires</p>
                <p className="font-medium text-gray-900">
                  {new Date(stats.ca.expires).toLocaleDateString()}
                </p>
              </div>
            )}
            {stats.ca.vars && (
              <div>
                <p className="text-sm text-gray-500">Organization</p>
                <p className="font-medium text-gray-900 text-sm">
                  {stats.ca.vars.org || 'Not configured'}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  {stats.ca.vars.country}, {stats.ca.vars.province}
                </p>
              </div>
            )}
          </div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
        >
          <div className="flex items-center">
            <div className="p-3 bg-blue-100 text-blue-600 rounded-full">
              <Award className="h-6 w-6" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Total Certificates</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.certificates.total}</p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
        >
          <div className="flex items-center">
            <div className="p-3 bg-purple-100 text-purple-600 rounded-full">
              <Server className="h-6 w-6" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Server Certificates</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.certificates.server}</p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
        >
          <div className="flex items-center">
            <div className="p-3 bg-green-100 text-green-600 rounded-full">
              <Users className="h-6 w-6" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Client Certificates</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.certificates.client}</p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
        >
          <div className="flex items-center">
            <div className={`p-3 rounded-full ${
              stats.expiring.critical > 0 
                ? 'bg-red-100 text-red-600' 
                : stats.expiring.warning > 0 
                ? 'bg-yellow-100 text-yellow-600' 
                : 'bg-green-100 text-green-600'
            }`}>
              <AlertTriangle className="h-6 w-6" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Expiring Soon</p>
              <p className="text-2xl font-semibold text-gray-900">
                {stats.expiring.critical + stats.expiring.warning}
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Expiration Status Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
        >
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Certificate Expiration Status</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={expirationData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, value }) => value > 0 ? `${name}: ${value}` : ''}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {expirationData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          
          {/* Custom Legend */}
          <div className="flex flex-wrap justify-center gap-4 mt-4">
            {expirationData.map((entry, index) => (
              <div key={index} className="flex items-center">
                <div 
                  className="w-3 h-3 rounded-full mr-2"
                  style={{ backgroundColor: entry.color }}
                ></div>
                <span className="text-sm text-gray-600">
                  {entry.name}: {entry.value}
                </span>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Certificate Types Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
        >
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Certificate Types</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={certificateTypeData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="count" fill="#3b82f6" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </motion.div>
      </div>

      {/* Recent Certificates */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.7 }}
        className="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
      >
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Certificates</h3>
        <div className="space-y-3">
          {stats.recent.length > 0 ? (
            stats.recent.map((cert, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center">
                  <div className={`p-2 rounded-full ${
                    cert.type === 'server' ? 'bg-purple-100 text-purple-600' : 'bg-green-100 text-green-600'
                  }`}>
                    {cert.type === 'server' ? <Server className="h-4 w-4" /> : <Users className="h-4 w-4" />}
                  </div>
                  <div className="ml-3">
                    <p className="font-medium text-gray-900">{cert.name}</p>
                    <p className="text-sm text-gray-500">
                      {cert.type.charAt(0).toUpperCase() + cert.type.slice(1)} Certificate
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-500">
                    Created {cert.created ? new Date(cert.created).toLocaleDateString() : 'Unknown'}
                  </p>
                  <p className="text-sm text-gray-500">
                    Expires {cert.expires ? new Date(cert.expires).toLocaleDateString() : 'Unknown'}
                  </p>
                </div>
              </div>
            ))
          ) : (
            <p className="text-gray-500 text-center py-8">No certificates found</p>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default Dashboard;