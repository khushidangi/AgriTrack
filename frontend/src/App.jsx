import React, { useState, useEffect } from 'react';
import {
  ComposedChart, Bar, Line, BarChart, CartesianGrid, XAxis, YAxis,
  Tooltip, Legend, ResponsiveContainer
} from 'recharts';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [showAddModal, setShowAddModal] = useState(false);
  const [farmerId, setFarmerId] = useState('');
  const [cropId, setCropId] = useState('');
  const [seasonId, setSeasonId] = useState('');
  const [yieldAmount, setYieldAmount] = useState('');
  const [rainfallAmount, setRainfallAmount] = useState('');

  const [stats, setStats] = useState(null);
  const [chartData, setChartData] = useState([]);
  const [records, setRecords] = useState([]);
  const [farmers, setFarmers] = useState([]);
  const [crops, setCrops] = useState([]);
  const [seasons, setSeasons] = useState([]);
  const [farmerSummary, setFarmerSummary] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [seasonReport, setSeasonReport] = useState(null);
  const [selectedReportSeason, setSelectedReportSeason] = useState('1');
  const [reportLoading, setReportLoading] = useState(false);

  const [recordsPage, setRecordsPage] = useState(0);
  const recordsPerPage = 10;

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchAll = async () => {
      try {
        setLoading(true);
        const [
          statsRes,
          chartRes,
          recordsRes,
          farmersRes,
          cropsRes,
          seasonsRes,
          summaryRes,
          analyticsRes
        ] = await Promise.all([
          fetch('/api/stats'),
          fetch('/api/chart'),
          fetch('/api/records'),
          fetch('/api/farmers'),
          fetch('/api/crops'),
          fetch('/api/seasons'),
          fetch('/api/farmers/summary'),
          fetch('/api/analytics')
        ]);

        if (!statsRes.ok || !chartRes.ok || !recordsRes.ok || !farmersRes.ok ||
            !cropsRes.ok || !seasonsRes.ok || !summaryRes.ok || !analyticsRes.ok) {
          throw new Error('Failed to fetch data');
        }

        const statsData = await statsRes.json();
        const chartDataData = await chartRes.json();
        const recordsData = await recordsRes.json();
        const farmersData = await farmersRes.json();
        const cropsData = await cropsRes.json();
        const seasonsData = await seasonsRes.json();
        const summaryData = await summaryRes.json();
        const analyticsData = await analyticsRes.json();

        setStats(statsData);
        setChartData(chartDataData);
        setRecords(recordsData);
        setFarmers(farmersData);
        setCrops(cropsData);
        setSeasons(seasonsData);
        setFarmerSummary(summaryData);
        setAnalytics(analyticsData);
        setError(null);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchAll();
  }, []);

  const handleAddRecord = async () => {
    if (!farmerId || !cropId || !seasonId || !yieldAmount) {
      alert('Please fill in all required fields');
      return;
    }

    try {
      const res = await fetch('/api/records', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          farmer_id: parseInt(farmerId),
          crop_id: parseInt(cropId),
          season_id: parseInt(seasonId),
          yield_amount: parseFloat(yieldAmount),
          rainfall_amount: rainfallAmount ? parseFloat(rainfallAmount) : null
        })
      });

      if (!res.ok) throw new Error('Failed to add record');

      const recordsRes = await fetch('/api/records');
      if (recordsRes.ok) {
        setRecords(await recordsRes.json());
      }

      setShowAddModal(false);
      setFarmerId('');
      setCropId('');
      setSeasonId('');
      setYieldAmount('');
      setRainfallAmount('');
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const handleDeleteRecord = async (yieldId) => {
    if (!confirm('Delete this record?')) return;

    try {
      const res = await fetch(`/api/records/${yieldId}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Failed to delete record');

      const recordsRes = await fetch('/api/records');
      if (recordsRes.ok) {
        setRecords(await recordsRes.json());
      }
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const handleGenerateReport = async () => {
    if (!selectedReportSeason) return;

    try {
      setReportLoading(true);
      const res = await fetch(`/api/season/${selectedReportSeason}/report`);
      if (!res.ok) throw new Error('Failed to generate report');
      const data = await res.json();
      setSeasonReport(data);
    } catch (err) {
      alert('Error: ' + err.message);
    } finally {
      setReportLoading(false);
    }
  };

  const styles = `
    @import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Mono:wght@400;500&display=swap');
    @import url('https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css');

    :root {
      --bg: #080e08;
      --bg-2: #0d140d;
      --sidebar: #0b1a0c;
      --sidebar-active: #163a18;
      --surface: #111a11;
      --surface-2: #162016;
      --border: #1e2e1e;
      --border-light: #253525;
      --green-bright: #4afa8a;
      --green-mid: #2d7a3a;
      --green-dim: #1a4d22;
      --green-text: #6fcf7f;
      --amber: #f5c842;
      --red: #f25c5c;
      --blue: #4a9afa;
      --text: #e8ede9;
      --text-muted: #7a9a7e;
      --text-dim: #4a6a4e;
      --hero-bg: #0f2e14;
      --hero-border: #1e5225;
      --pill-green-bg: #0d2e10;
      --pill-green-text: #4afa8a;
      --pill-red-bg: #2e0d0d;
      --pill-red-text: #f25c5c;
      --head: 'Syne', sans-serif;
      --mono: 'DM Mono', monospace;
    }

    * { box-sizing: border-box; }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: var(--mono);
      font-size: 13px;
      margin: 0;
    }

    #root {
      display: flex;
      height: 100vh;
    }

    .sidebar {
      width: 200px;
      background: var(--sidebar);
      border-right: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      padding: 24px 16px;
      position: relative;
    }

    .sidebar-brand {
      font-family: var(--head);
      font-size: 20px;
      font-weight: 800;
      color: var(--green-bright);
      margin-bottom: 6px;
    }

    .sidebar-tagline {
      font-size: 9px;
      color: var(--text-dim);
      letter-spacing: 2px;
      text-transform: uppercase;
      margin-bottom: 24px;
    }

    .nav-items {
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .nav-item {
      padding: 10px 16px;
      display: flex;
      align-items: center;
      gap: 10px;
      cursor: pointer;
      color: var(--text-muted);
      border-radius: 0 6px 6px 0;
      font-size: 12px;
      transition: all 0.2s;
    }

    .nav-item.active {
      background: var(--sidebar-active);
      border-left: 2px solid var(--green-bright);
      padding-left: 14px;
      color: var(--text);
    }

    .nav-item i {
      width: 16px;
      height: 16px;
    }

    .sidebar-bottom {
      position: absolute;
      bottom: 20px;
      width: calc(100% - 32px);
    }

    .btn-season-report {
      border: 1px solid var(--green-mid);
      color: var(--green-text);
      background: transparent;
      padding: 10px 14px;
      font-family: var(--mono);
      font-size: 11px;
      letter-spacing: 1px;
      text-transform: uppercase;
      cursor: pointer;
      width: 100%;
      border-radius: 4px;
      transition: all 0.2s;
    }

    .btn-season-report:hover {
      background: rgba(74, 250, 138, 0.05);
    }

    .main-container {
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    .header {
      height: 56px;
      background: var(--bg-2);
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      padding: 0 24px;
      justify-content: space-between;
    }

    .header-title {
      font-family: var(--head);
      font-size: 16px;
      font-weight: 600;
      color: var(--text);
    }

    .header-search {
      background: var(--surface);
      border: 1px solid var(--border);
      color: var(--text-muted);
      padding: 8px 14px;
      font-family: var(--mono);
      font-size: 12px;
      border-radius: 4px;
      width: 280px;
    }

    .header-search::placeholder {
      color: var(--text-muted);
    }

    .header-right {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .header-icon {
      color: var(--text-muted);
      cursor: pointer;
      font-size: 18px;
    }

    .avatar {
      width: 32px;
      height: 32px;
      background: var(--green-dim);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--green-bright);
      font-size: 11px;
      font-weight: 700;
    }

    .user-profile {
      display: flex;
      flex-direction: column;
    }

    .user-profile-label {
      color: var(--text);
      font-size: 11px;
      font-weight: 600;
    }

    .user-profile-sub {
      color: var(--text-muted);
      font-size: 10px;
    }

    .content {
      flex: 1;
      overflow-y: auto;
      padding: 24px;
      background: var(--bg);
    }

    .section-title {
      font-family: var(--head);
      font-size: 22px;
      font-weight: 700;
      color: var(--text);
      margin-bottom: 4px;
    }

    .section-subtitle {
      color: var(--text-muted);
      font-size: 13px;
      margin-bottom: 24px;
    }

    .hero-card {
      background: var(--hero-bg);
      border: 1px solid var(--hero-border);
      border-radius: 10px;
      padding: 28px 32px;
      display: flex;
      gap: 40px;
      margin-bottom: 20px;
    }

    .hero-left {
      flex: 0.6;
    }

    .hero-title {
      font-family: var(--head);
      font-size: 26px;
      font-weight: 700;
      color: var(--text);
      margin-bottom: 8px;
    }

    .hero-subtitle {
      color: var(--text-muted);
      font-size: 13px;
      line-height: 1.5;
      margin-bottom: 20px;
    }

    .chips {
      display: flex;
      gap: 24px;
      margin-bottom: 20px;
    }

    .chip {
      display: flex;
      flex-direction: column;
    }

    .chip-label {
      color: var(--text-muted);
      font-size: 9px;
      text-transform: uppercase;
      margin-bottom: 4px;
      letter-spacing: 0.5px;
    }

    .chip-value {
      font-family: var(--head);
      font-size: 20px;
      font-weight: 700;
      color: var(--text);
    }

    .action-buttons {
      display: flex;
      gap: 10px;
    }

    .btn {
      border: none;
      padding: 9px 16px;
      font-size: 12px;
      cursor: pointer;
      border-radius: 4px;
      font-family: var(--mono);
      transition: all 0.2s;
    }

    .btn-primary {
      background: var(--green-dim);
      color: var(--text);
    }

    .btn-primary:hover {
      background: var(--green-mid);
    }

    .btn-secondary {
      background: var(--surface-2);
      border: 1px solid var(--border-light);
      color: var(--text);
    }

    .btn-secondary:hover {
      background: rgba(74, 250, 138, 0.05);
    }

    .hero-right {
      flex: 0.4;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .hero-icon {
      font-size: 120px;
      color: var(--green-dim);
      opacity: 0.3;
    }

    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;
      margin-bottom: 20px;
    }

    .metric-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 16px 18px;
    }

    .metric-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }

    .metric-label {
      color: var(--text-muted);
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .badge {
      background: var(--pill-green-bg);
      color: var(--pill-green-text);
      padding: 2px 6px;
      font-size: 9px;
      border-radius: 3px;
    }

    .badge.red {
      background: var(--pill-red-bg);
      color: var(--pill-red-text);
    }

    .metric-value {
      font-family: var(--head);
      font-size: 24px;
      font-weight: 700;
      color: var(--text);
      margin-bottom: 4px;
    }

    .metric-sub {
      color: var(--text-muted);
      font-size: 12px;
      margin-bottom: 12px;
    }

    .bottom-row {
      display: grid;
      grid-template-columns: 40% 60%;
      gap: 16px;
      margin-top: 20px;
    }

    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      overflow: hidden;
    }

    .card-header {
      padding: 14px 18px;
      border-bottom: 1px solid var(--border);
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-family: var(--head);
      font-size: 14px;
      font-weight: 600;
      color: var(--text);
    }

    .card-link {
      color: var(--green-text);
      font-size: 11px;
      cursor: pointer;
    }

    .activity-list {
      padding: 0;
    }

    .activity-item {
      padding: 12px 18px;
      display: flex;
      gap: 12px;
      border-bottom: 1px solid var(--border);
      align-items: flex-start;
    }

    .activity-avatar {
      width: 20px;
      height: 20px;
      background: var(--green-dim);
      color: var(--green-bright);
      border-radius: 4px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 9px;
      font-weight: 700;
      flex-shrink: 0;
    }

    .activity-content {
      flex: 1;
    }

    .activity-title {
      color: var(--text);
      font-size: 13px;
      margin-bottom: 2px;
    }

    .activity-sub {
      color: var(--text-muted);
      font-size: 11px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }

    thead th {
      padding: 10px 16px;
      text-align: left;
      font-size: 10px;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      color: var(--text-dim);
      border-bottom: 1px solid var(--border);
      background: var(--surface);
      font-weight: 600;
    }

    tbody td {
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
      color: var(--text);
    }

    tbody tr:hover {
      background: rgba(74, 250, 138, 0.03);
    }

    .row-farmer {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .farmer-avatar {
      width: 30px;
      height: 30px;
      background: var(--green-dim);
      color: var(--green-bright);
      border-radius: 4px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 10px;
      font-weight: 700;
      flex-shrink: 0;
    }

    .farmer-info {
      display: flex;
      flex-direction: column;
    }

    .farmer-name {
      color: var(--text);
      font-size: 13px;
      font-weight: 600;
    }

    .farmer-location {
      color: var(--text-muted);
      font-size: 11px;
    }

    .pill-status {
      background: var(--pill-green-bg);
      color: var(--pill-green-text);
      padding: 3px 8px;
      border-radius: 3px;
      font-size: 10px;
      text-transform: uppercase;
      font-weight: 600;
    }

    .pill-status.review {
      background: var(--pill-red-bg);
      color: var(--pill-red-text);
    }

    .btn-actions {
      background: transparent;
      border: none;
      color: var(--text-muted);
      cursor: pointer;
      font-size: 16px;
      padding: 0;
    }

    .btn-del {
      background: transparent;
      border: 1px solid var(--red);
      color: var(--red);
      padding: 3px 8px;
      font-size: 11px;
      cursor: pointer;
      border-radius: 3px;
      transition: all 0.2s;
    }

    .btn-del:hover {
      background: rgba(242, 92, 92, 0.1);
    }

    .pagination {
      display: flex;
      justify-content: center;
      gap: 8px;
      padding: 12px 0;
      border-top: 1px solid var(--border);
      margin-top: 12px;
    }

    .page-btn {
      background: transparent;
      border: 1px solid var(--border);
      color: var(--text-muted);
      padding: 4px 8px;
      cursor: pointer;
      border-radius: 3px;
      font-size: 11px;
    }

    .page-btn.active {
      background: var(--green-dim);
      color: var(--green-bright);
      border-color: var(--green-dim);
    }

    .page-btn:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.7);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
    }

    .modal {
      background: #1a2a1a;
      border: 1px solid var(--border-light);
      border-radius: 10px;
      padding: 28px 32px;
      width: 480px;
      max-width: 90vw;
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 20px;
    }

    .modal-title {
      font-family: var(--head);
      font-size: 16px;
      font-weight: 600;
      color: var(--text);
    }

    .modal-subtitle {
      color: var(--text-muted);
      font-size: 13px;
      margin-bottom: 16px;
    }

    .modal-close {
      background: none;
      border: none;
      color: var(--text-muted);
      font-size: 20px;
      cursor: pointer;
      padding: 0;
    }

    .form-group {
      margin-bottom: 16px;
    }

    .form-group-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .form-label {
      display: block;
      font-size: 10px;
      color: var(--text-muted);
      text-transform: uppercase;
      margin-bottom: 6px;
      letter-spacing: 0.5px;
    }

    .form-control {
      width: 100%;
      background: var(--surface);
      border: 1px solid var(--border-light);
      color: var(--text);
      padding: 10px 12px;
      font-family: var(--mono);
      font-size: 13px;
      border-radius: 4px;
    }

    .form-control:focus {
      outline: none;
      border-color: var(--green-mid);
    }

    .info-box {
      background: var(--hero-bg);
      border: 1px solid var(--hero-border);
      border-radius: 6px;
      padding: 12px;
      margin-bottom: 20px;
      display: flex;
      gap: 10px;
      align-items: flex-start;
    }

    .info-box-icon {
      color: var(--green-text);
      font-size: 14px;
      flex-shrink: 0;
      margin-top: 2px;
    }

    .info-box-content {
      flex: 1;
    }

    .info-box-label {
      color: var(--green-text);
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 4px;
    }

    .info-box-text {
      color: var(--text-muted);
      font-size: 12px;
      line-height: 1.4;
    }

    .modal-buttons {
      display: flex;
      gap: 12px;
      justify-content: flex-end;
      margin-top: 20px;
    }

    .btn-save {
      background: var(--green-mid);
      color: var(--text);
      border: none;
      padding: 10px 24px;
      font-size: 13px;
      font-family: var(--head);
      font-weight: 600;
      cursor: pointer;
      border-radius: 4px;
      transition: all 0.2s;
    }

    .btn-save:hover {
      background: var(--green-bright);
      color: var(--bg);
    }

    .btn-cancel {
      background: transparent;
      border: 1px solid var(--border-light);
      color: var(--text-muted);
      padding: 10px 24px;
      cursor: pointer;
      border-radius: 4px;
      font-family: var(--mono);
      font-size: 13px;
      transition: all 0.2s;
    }

    .btn-cancel:hover {
      border-color: var(--text-muted);
      color: var(--text);
    }

    .action-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .filter-chips {
      display: flex;
      gap: 8px;
    }

    .chip-filter {
      background: var(--surface);
      border: 1px solid var(--border);
      color: var(--text-muted);
      padding: 6px 12px;
      font-size: 11px;
      cursor: pointer;
      border-radius: 4px;
      transition: all 0.2s;
    }

    .chip-filter:hover {
      border-color: var(--green-mid);
      color: var(--text);
    }

    .error {
      color: var(--red);
      font-size: 12px;
      padding: 24px;
      text-align: center;
    }

    .loading {
      color: var(--text-muted);
      font-size: 12px;
      padding: 24px;
      text-align: center;
    }

    .pest-pill-high {
      background: rgba(242, 92, 92, 0.1);
      color: var(--red);
    }

    .pest-pill-medium {
      background: rgba(245, 200, 66, 0.1);
      color: var(--amber);
    }

    .pest-pill-low {
      background: transparent;
      color: var(--text-muted);
    }

    .rainfall-pill-low {
      background: var(--pill-red-bg);
      color: var(--pill-red-text);
    }

    .rainfall-pill-moderate {
      background: var(--pill-green-bg);
      color: var(--pill-green-text);
    }

    .rainfall-pill-high {
      background: rgba(74, 154, 250, 0.1);
      color: var(--blue);
    }

    .circle-progress {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: conic-gradient(var(--green-mid) 0% 60%, var(--border) 60% 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      color: var(--green-bright);
      font-size: 11px;
    }

    .progress-value {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
    }

    .severity-stats {
      display: flex;
      gap: 16px;
      justify-content: center;
    }

    .severity-stat {
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    .severity-number {
      font-family: var(--head);
      font-size: 18px;
      font-weight: 700;
      margin-bottom: 4px;
    }

    .severity-label {
      font-size: 10px;
      text-transform: uppercase;
    }

    .report-info {
      background: var(--hero-bg);
      border: 1px solid var(--hero-border);
      border-radius: 6px;
      padding: 12px;
      margin-bottom: 16px;
      color: var(--text-muted);
      font-size: 12px;
    }

    .gen-controls {
      display: flex;
      gap: 12px;
      margin-bottom: 16px;
    }

    .gen-controls select {
      background: var(--surface);
      border: 1px solid var(--border-light);
      color: var(--text);
      padding: 8px 12px;
      font-family: var(--mono);
      font-size: 12px;
      border-radius: 4px;
    }

    .gen-controls button {
      background: var(--green-mid);
      color: var(--text);
      border: none;
      padding: 8px 16px;
      font-size: 12px;
      cursor: pointer;
      border-radius: 4px;
    }

    .gen-controls button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `;

  const handleNavClick = (tab) => {
    setActiveTab(tab);
    setRecordsPage(0);
  };

  if (loading && !stats) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
        <div className="loading">Loading...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
        <div className="error">Error: {error}</div>
      </div>
    );
  }

  const paginatedRecords = records.slice(recordsPage * recordsPerPage, (recordsPage + 1) * recordsPerPage);
  const totalPages = Math.ceil(records.length / recordsPerPage);

  const getFarmInitials = (name) => name.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase();

  const formatValue = (val) => {
    if (val >= 1000) return (val / 1000).toFixed(1) + 'k';
    return Math.round(val).toString();
  };

  const hardcodedPestReports = [
    { farmer: 'Rajinder Singh', crop: 'Rice', season: 'Kharif 2022', pest: 'Stem Borer', severity: 'MEDIUM' },
    { farmer: 'Gurpreet Kaur', crop: 'Rice', season: 'Kharif 2022', pest: 'Leaf Folder', severity: 'LOW' },
    { farmer: 'Harjit Sandhu', crop: 'Maize', season: 'Kharif 2022', pest: 'Armyworm', severity: 'HIGH' },
    { farmer: 'Sukhdev Brar', crop: 'Sugarcane', season: 'Kharif 2022', pest: 'Scale Insect', severity: 'MEDIUM' },
    { farmer: 'Priya Sharma', crop: 'Rice', season: 'Kharif 2023', pest: 'Brown Spot', severity: 'LOW' },
    { farmer: 'Vikram Patel', crop: 'Maize', season: 'Kharif 2023', pest: 'Stem Borer', severity: 'MEDIUM' }
  ];

  return (
    <>
      <style>{styles}</style>
      <div className="sidebar">
        <div className="sidebar-brand">AgriDB</div>
        <div className="sidebar-tagline">Agri Stewardship</div>
        <div className="nav-items">
          <div className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`} onClick={() => handleNavClick('dashboard')}>
            <i className="ti ti-layout-dashboard"></i>
            Dashboard
          </div>
          <div className={`nav-item ${activeTab === 'records' ? 'active' : ''}`} onClick={() => handleNavClick('records')}>
            <i className="ti ti-user"></i>
            Farmers
          </div>
          <div className={`nav-item ${activeTab === 'records' ? 'active' : ''}`} onClick={() => handleNavClick('records')}>
            <i className="ti ti-plant"></i>
            Crops & Yield
          </div>
          <div className={`nav-item ${activeTab === 'records' ? 'active' : ''}`} onClick={() => handleNavClick('records')}>
            <i className="ti ti-calendar"></i>
            Seasons
          </div>
          <div className={`nav-item ${activeTab === 'records' ? 'active' : ''}`} onClick={() => handleNavClick('records')}>
            <i className="ti ti-cloud-rain"></i>
            Rainfall
          </div>
          <div className={`nav-item ${activeTab === 'pest' ? 'active' : ''}`} onClick={() => handleNavClick('pest')}>
            <i className="ti ti-bug"></i>
            Pest Control
          </div>
          <div className={`nav-item ${activeTab === 'records' ? 'active' : ''}`} onClick={() => handleNavClick('records')}>
            <i className="ti ti-layers"></i>
            Soil Analysis
          </div>
          <div className={`nav-item ${activeTab === 'analytics' ? 'active' : ''}`} onClick={() => handleNavClick('analytics')}>
            <i className="ti ti-chart-bar"></i>
            Analytics
          </div>
        </div>
        <div className="sidebar-bottom">
          <button className="btn-season-report" onClick={() => { setActiveTab('analytics'); setSelectedReportSeason('1'); }}>
            + New Season Report
          </button>
        </div>
      </div>

      <div className="main-container">
        <div className="header">
          <div className="header-title">
            {activeTab === 'dashboard' && 'Dashboard'}
            {activeTab === 'records' && 'Yield Records'}
            {activeTab === 'analytics' && 'Analytics'}
            {activeTab === 'pest' && 'Pest Control'}
          </div>
          <input type="text" className="header-search" placeholder="Search database..." />
          <div className="header-right">
            <i className="ti ti-bell header-icon"></i>
            <i className="ti ti-settings header-icon"></i>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div className="avatar">CM</div>
              <div className="user-profile">
                <div className="user-profile-label">Manager Profile</div>
                <div className="user-profile-sub">Admin Access</div>
              </div>
            </div>
          </div>
        </div>

        <div className="content">
          {activeTab === 'dashboard' && (
            <>
              <div className="hero-card">
                <div className="hero-left">
                  <div className="hero-title">Welcome back, Corporate Manager</div>
                  <div className="hero-subtitle">
                    Your operational oversight for the current harvest cycle is centralized here. Precision data ensures maximum stewardship of your agricultural assets.
                  </div>
                  <div className="chips">
                    <div className="chip">
                      <div className="chip-label">Total Farmers</div>
                      <div className="chip-value">{stats?.total_farmers || 0}</div>
                    </div>
                    <div className="chip">
                      <div className="chip-label">Active Seasons</div>
                      <div className="chip-value">6</div>
                    </div>
                    <div className="chip">
                      <div className="chip-label">Avg. Yield</div>
                      <div className="chip-value">{formatValue(stats?.avg_yield || 0)}</div>
                    </div>
                  </div>
                  <div className="action-buttons">
                    <button className="btn btn-primary">+ New Farmer</button>
                    <button className="btn btn-secondary">Log Yield</button>
                    <button className="btn btn-secondary"><i className="ti ti-alert-triangle" style={{ marginRight: '4px' }}></i>Pest Report</button>
                  </div>
                </div>
                <div className="hero-right">
                  <div className="hero-icon ti ti-plant"></div>
                </div>
              </div>

              <div className="metrics-grid">
                <div className="metric-card">
                  <div className="metric-header">
                    <div className="metric-label">Total Yield</div>
                    <div className="badge">+12%</div>
                  </div>
                  <div className="metric-value">{formatValue(stats?.total_yield || 0)}</div>
                  <div className="metric-sub">Tons</div>
                  <ResponsiveContainer width="100%" height={40}>
                    <BarChart data={chartData}>
                      <Bar dataKey="Total_Yield" fill="var(--green-mid)" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>

                <div className="metric-card">
                  <div className="metric-header">
                    <div className="metric-label">Avg Rainfall</div>
                    <div style={{ color: 'var(--text-dim)', fontSize: '9px' }}>Last 30 Days</div>
                  </div>
                  <div className="metric-value">{Math.round(stats?.avg_rainfall || 0)}</div>
                  <div className="metric-sub">mm</div>
                  <ResponsiveContainer width="100%" height={40}>
                    <BarChart data={chartData}>
                      <Bar dataKey="Rainfall" fill="var(--blue)" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>

                <div className="metric-card">
                  <div className="metric-label">Top Farmer</div>
                  <div className="metric-value" style={{ fontSize: '18px', marginTop: '8px' }}>{stats?.top_farmer || '—'}</div>
                  <div className="metric-sub">Highest yield producer</div>
                  <div className="circle-progress">60%</div>
                </div>

                <div className="metric-card">
                  <div className="metric-header">
                    <div className="metric-label">Active Pest Reports</div>
                    <div className="badge red">URGENT</div>
                  </div>
                  <div className="severity-stats">
                    <div className="severity-stat">
                      <div className="severity-number" style={{ color: 'var(--red)' }}>3</div>
                      <div className="severity-label">HIGH</div>
                    </div>
                    <div className="severity-stat">
                      <div className="severity-number" style={{ color: 'var(--amber)' }}>12</div>
                      <div className="severity-label">MEDIUM</div>
                    </div>
                    <div className="severity-stat">
                      <div className="severity-number" style={{ color: 'var(--text-muted)' }}>24</div>
                      <div className="severity-label">LOW</div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bottom-row">
                <div className="card">
                  <div className="card-header">
                    Recent Activity
                    <div className="card-link" onClick={() => handleNavClick('records')}>View All</div>
                  </div>
                  <div className="activity-list">
                    {records.slice(0, 5).map((rec, i) => (
                      <div key={i} className="activity-item">
                        <div className="activity-avatar">{getFarmInitials(rec.Farmer)}</div>
                        <div className="activity-content">
                          <div className="activity-title">Logged yield for {rec.Crop} {rec.Season}</div>
                          <div className="activity-sub">Farmer: {rec.Farmer}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="card">
                  <div className="card-header">Farmer Yield Summary</div>
                  <table>
                    <thead>
                      <tr>
                        <th>FARMER ENTITY</th>
                        <th>TOTAL RECORDS</th>
                        <th>TOTAL YIELD</th>
                        <th>STATUS</th>
                        <th>ACTIONS</th>
                      </tr>
                    </thead>
                    <tbody>
                      {farmerSummary.slice(0, 5).map((f, i) => (
                        <tr key={i}>
                          <td>
                            <div className="row-farmer">
                              <div className="farmer-avatar">{getFarmInitials(f.Name)}</div>
                              <div className="farmer-info">
                                <div className="farmer-name">{f.Name}</div>
                                <div className="farmer-location">{f.Location}</div>
                              </div>
                            </div>
                          </td>
                          <td>{f.Total_Records}</td>
                          <td>{formatValue(f.Total_Yield)} kg</td>
                          <td>
                            <div className={`pill-status ${f.Total_Yield > 5000 ? '' : 'review'}`}>
                              {f.Total_Yield > 5000 ? 'In Progress' : 'Review'}
                            </div>
                          </td>
                          <td><button className="btn-actions">⋮</button></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}

          {activeTab === 'records' && (
            <>
              <div className="section-title">Yield Records</div>
              <div className="section-subtitle">Manage crop production data across all registered farmers</div>

              <div className="action-bar">
                <div className="filter-chips">
                  <div className="chip-filter">All Locations ▾</div>
                  <div className="chip-filter">Top Producers ▾</div>
                </div>
                <button className="btn btn-primary" onClick={() => setShowAddModal(true)}>+ Add Record</button>
              </div>

              <div className="card">
                <div className="card-header">Farmer Registry <span style={{ color: 'var(--text-muted)' }}>({records.length} records)</span></div>
                <table>
                  <thead>
                    <tr>
                      <th>FARMER</th>
                      <th>LOCATION</th>
                      <th>CROP</th>
                      <th>SEASON</th>
                      <th>YIELD (KG)</th>
                      <th>YIELD/HA</th>
                      <th>DEL</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedRecords.map((rec, i) => (
                      <tr key={i}>
                        <td>
                          <div className="row-farmer">
                            <div className="farmer-avatar">{getFarmInitials(rec.Farmer)}</div>
                            <div className="farmer-info">
                              <div className="farmer-name">{rec.Farmer}</div>
                            </div>
                          </div>
                        </td>
                        <td>{rec.Location || '—'}</td>
                        <td>{rec.Crop}</td>
                        <td>{rec.Season}</td>
                        <td>{formatValue(rec.Yield)}</td>
                        <td>{rec.Yield_Per_Ha}</td>
                        <td>
                          <button className="btn-del" onClick={() => handleDeleteRecord(rec.Yield_ID)}>Del</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <div className="pagination">
                  <button className="page-btn" disabled={recordsPage === 0} onClick={() => setRecordsPage(p => p - 1)}>← Previous</button>
                  {Array.from({ length: totalPages }, (_, i) => (
                    <button
                      key={i}
                      className={`page-btn ${recordsPage === i ? 'active' : ''}`}
                      onClick={() => setRecordsPage(i)}
                    >
                      {i + 1}
                    </button>
                  ))}
                  <button className="page-btn" disabled={recordsPage === totalPages - 1} onClick={() => setRecordsPage(p => p + 1)}>Next →</button>
                </div>
              </div>

              {showAddModal && (
                <div className="modal-overlay">
                  <div className="modal">
                    <div className="modal-header">
                      <div>
                        <div className="modal-title">Add New Farmer</div>
                        <div className="modal-subtitle">Onboard a new producer to the database.</div>
                      </div>
                      <button className="modal-close" onClick={() => setShowAddModal(false)}>✕</button>
                    </div>

                    <div className="form-group">
                      <label className="form-label">Farmer</label>
                      <select className="form-control" value={farmerId} onChange={(e) => setFarmerId(e.target.value)}>
                        <option value="">Select farmer...</option>
                        {farmers.map(f => <option key={f.Farmer_ID} value={f.Farmer_ID}>{f.Name}</option>)}
                      </select>
                    </div>

                    <div className="form-group-row">
                      <div>
                        <label className="form-label">Crop</label>
                        <select className="form-control" value={cropId} onChange={(e) => setCropId(e.target.value)}>
                          <option value="">Select crop...</option>
                          {crops.map(c => <option key={c.Crop_ID} value={c.Crop_ID}>{c.Crop_Name}</option>)}
                        </select>
                      </div>
                      <div>
                        <label className="form-label">Season</label>
                        <select className="form-control" value={seasonId} onChange={(e) => setSeasonId(e.target.value)}>
                          <option value="">Select season...</option>
                          {seasons.map(s => <option key={s.Season_ID} value={s.Season_ID}>{s.Season_Name} {s.Year}</option>)}
                        </select>
                      </div>
                    </div>

                    <div className="form-group-row">
                      <div>
                        <label className="form-label">Yield Amount (KG)</label>
                        <input type="number" className="form-control" placeholder="e.g. 4500" value={yieldAmount} onChange={(e) => setYieldAmount(e.target.value)} />
                      </div>
                      <div>
                        <label className="form-label">Rainfall (MM)</label>
                        <input type="number" className="form-control" placeholder="optional" value={rainfallAmount} onChange={(e) => setRainfallAmount(e.target.value)} />
                      </div>
                    </div>

                    <div className="info-box">
                      <div className="info-box-icon ti ti-info-circle"></div>
                      <div className="info-box-content">
                        <div className="info-box-label">Next Steps</div>
                        <div className="info-box-text">This record will be stored via Insert_Yield_Record stored procedure with full validation and audit logging.</div>
                      </div>
                    </div>

                    <div className="modal-buttons">
                      <button className="btn-cancel" onClick={() => setShowAddModal(false)}>Cancel</button>
                      <button className="btn-save" onClick={handleAddRecord}>Save Record</button>
                    </div>
                  </div>
                </div>
              )}
            </>
          )}

          {activeTab === 'analytics' && (
            <>
              <div className="section-title">Analytics</div>
              <div className="section-subtitle">Agricultural performance across all seasons and farmers</div>

              {analytics && (
                <>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', marginBottom: '20px' }}>
                    <div className="card" style={{ padding: '16px 18px' }}>
                      <div className="metric-label">Top Farmer</div>
                      <div className="metric-value">{analytics.summary.Top_Farmer}</div>
                      <div className="metric-sub">{formatValue(analytics.summary.Top_Farmer_Yield)} kg</div>
                    </div>
                    <div className="card" style={{ padding: '16px 18px' }}>
                      <div className="metric-label">Top Crop</div>
                      <div className="metric-value">{analytics.summary.Top_Crop}</div>
                      <div className="metric-sub">{formatValue(analytics.summary.Top_Crop_Total)} kg</div>
                    </div>
                    <div className="card" style={{ padding: '16px 18px' }}>
                      <div className="metric-label">Avg Rainfall</div>
                      <div className="metric-value">{Math.round(analytics.summary.Average_Rainfall)}</div>
                      <div className="metric-sub">mm</div>
                    </div>
                  </div>

                  <div className="card">
                    <div className="card-header">Seasonal Performance</div>
                    <table>
                      <thead>
                        <tr>
                          <th>SEASON</th>
                          <th>TOTAL YIELD</th>
                          <th>RAINFALL</th>
                          <th>RAINFALL CATEGORY</th>
                          <th>FARMERS</th>
                        </tr>
                      </thead>
                      <tbody>
                        {analytics.seasonal_comparison.map((s, i) => (
                          <tr key={i}>
                            <td>{s.Season}</td>
                            <td>{formatValue(s.Total_Yield)} kg</td>
                            <td>{Math.round(s.Rainfall)} mm</td>
                            <td>
                              <span className={`pill-status rainfall-pill-${s.Rainfall_Category.toLowerCase()}`} style={{ padding: '3px 8px', borderRadius: '3px', fontSize: '10px' }}>
                                {s.Rainfall_Category}
                              </span>
                            </td>
                            <td>—</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  <div className="card" style={{ marginTop: '16px', padding: '16px 18px' }}>
                    <ResponsiveContainer width="100%" height={240}>
                      <ComposedChart data={analytics.seasonal_comparison}>
                        <CartesianGrid stroke="var(--border)" strokeDasharray="3 3" />
                        <XAxis dataKey="Season" tick={{ fill: 'var(--text-muted)', fontSize: 11 }} axisLine={false} tickLine={false} />
                        <YAxis tick={{ fill: 'var(--text-muted)', fontSize: 11 }} axisLine={false} tickLine={false} />
                        <Tooltip contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', fontFamily: 'var(--mono)', fontSize: 12 }} />
                        <Bar dataKey="Total_Yield" fill="var(--green-mid)" />
                        <Line type="monotone" dataKey="Rainfall" stroke="var(--blue)" dot={false} />
                      </ComposedChart>
                    </ResponsiveContainer>
                  </div>
                </>
              )}

              <div className="card" style={{ marginTop: '20px' }}>
                <div className="card-header">Season Report Generator</div>
                <div style={{ padding: '16px 18px' }}>
                  <div className="report-info">Powered by Generate_Season_Report() cursor-based stored procedure</div>
                  <div className="gen-controls">
                    <select value={selectedReportSeason} onChange={(e) => setSelectedReportSeason(e.target.value)}>
                      {seasons.map(s => <option key={s.Season_ID} value={s.Season_ID}>{s.Season_Name} {s.Year}</option>)}
                    </select>
                    <button onClick={handleGenerateReport} disabled={reportLoading}>
                      {reportLoading ? 'Generating...' : 'Generate Report'}
                    </button>
                  </div>

                  {reportLoading && <div className="loading">Generating report via cursor procedure...</div>}

                  {seasonReport && (
                    <table>
                      <thead>
                        <tr>
                          <th>FARMER</th>
                          <th>TOTAL YIELD (ALL SEASONS)</th>
                          <th>YIELD/HA (THIS SEASON)</th>
                          <th>RAINFALL CATEGORY</th>
                        </tr>
                      </thead>
                      <tbody>
                        {seasonReport.map((r, i) => (
                          <tr key={i}>
                            <td>{r.Farmer_Name}</td>
                            <td>{formatValue(r.Total_Yield)} kg</td>
                            <td>{r.Yield_Per_Hectare}</td>
                            <td>
                              <span className="pill-status" style={{
                                background: r.Rainfall_Category === 'LOW' ? 'var(--pill-red-bg)' :
                                  r.Rainfall_Category === 'MODERATE' ? 'var(--pill-green-bg)' :
                                  'rgba(74, 154, 250, 0.1)',
                                color: r.Rainfall_Category === 'LOW' ? 'var(--pill-red-text)' :
                                  r.Rainfall_Category === 'MODERATE' ? 'var(--pill-green-text)' :
                                  'var(--blue)',
                                padding: '3px 8px', borderRadius: '3px', fontSize: '10px'
                              }}>
                                {r.Rainfall_Category}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              </div>
            </>
          )}

          {activeTab === 'pest' && (
            <>
              <div className="section-title">Pest Control</div>
              <div className="section-subtitle">Monitor and manage pest reports across all farms</div>

              <div className="card">
                <div className="card-header">Pest Reports</div>
                <table>
                  <thead>
                    <tr>
                      <th>FARMER</th>
                      <th>CROP</th>
                      <th>SEASON</th>
                      <th>PEST TYPE</th>
                      <th>SEVERITY</th>
                      <th>DATE</th>
                    </tr>
                  </thead>
                  <tbody>
                    {hardcodedPestReports.map((p, i) => (
                      <tr key={i}>
                        <td>{p.farmer}</td>
                        <td>{p.crop}</td>
                        <td>{p.season}</td>
                        <td>{p.pest}</td>
                        <td>
                          <span className={`pill-status pest-pill-${p.severity.toLowerCase()}`} style={{ padding: '3px 8px', borderRadius: '3px', fontSize: '10px' }}>
                            {p.severity}
                          </span>
                        </td>
                        <td>—</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="card" style={{ marginTop: '20px' }}>
                <div className="card-header">Season Report Generator</div>
                <div style={{ padding: '16px 18px' }}>
                  <div className="report-info">Powered by Generate_Season_Report() cursor-based stored procedure</div>
                  <div className="gen-controls">
                    <select value={selectedReportSeason} onChange={(e) => setSelectedReportSeason(e.target.value)}>
                      {seasons.map(s => <option key={s.Season_ID} value={s.Season_ID}>{s.Season_Name} {s.Year}</option>)}
                    </select>
                    <button onClick={handleGenerateReport} disabled={reportLoading}>
                      {reportLoading ? 'Generating...' : 'Generate Report'}
                    </button>
                  </div>

                  {reportLoading && <div className="loading">Generating report via cursor procedure...</div>}

                  {seasonReport && (
                    <table>
                      <thead>
                        <tr>
                          <th>FARMER</th>
                          <th>TOTAL YIELD (ALL SEASONS)</th>
                          <th>YIELD/HA (THIS SEASON)</th>
                          <th>RAINFALL CATEGORY</th>
                        </tr>
                      </thead>
                      <tbody>
                        {seasonReport.map((r, i) => (
                          <tr key={i}>
                            <td>{r.Farmer_Name}</td>
                            <td>{formatValue(r.Total_Yield)} kg</td>
                            <td>{r.Yield_Per_Hectare}</td>
                            <td>
                              <span className="pill-status" style={{
                                background: r.Rainfall_Category === 'LOW' ? 'var(--pill-red-bg)' :
                                  r.Rainfall_Category === 'MODERATE' ? 'var(--pill-green-bg)' :
                                  'rgba(74, 154, 250, 0.1)',
                                color: r.Rainfall_Category === 'LOW' ? 'var(--pill-red-text)' :
                                  r.Rainfall_Category === 'MODERATE' ? 'var(--pill-green-text)' :
                                  'var(--blue)',
                                padding: '3px 8px', borderRadius: '3px', fontSize: '10px'
                              }}>
                                {r.Rainfall_Category}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </>
  );
}
