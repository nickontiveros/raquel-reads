'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Cloud, Download, Upload, Trash2, AlertTriangle, CheckCircle, Loader2, HelpCircle, RefreshCw, Server } from 'lucide-react';
import { kindleService } from '@/lib/services/kindleService';
import { db } from '@/lib/db';
import { formatDistanceToNow } from 'date-fns';

export default function SettingsPage() {
  const [cookies, setCookies] = useState('');
  const [deviceToken, setDeviceToken] = useState('');
  const [tlsApiUrl, setTlsApiUrl] = useState('');
  const [isConnected, setIsConnected] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [lastSync, setLastSync] = useState<Date | null>(null);
  const [syncStatus, setSyncStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showInstructions, setShowInstructions] = useState(false);
  const [showDeployInstructions, setShowDeployInstructions] = useState(false);

  // Load existing credentials on mount
  useEffect(() => {
    const loadCredentials = async () => {
      const creds = await kindleService.getCredentials();
      if (creds) {
        setCookies(creds.cookies);
        setDeviceToken(creds.deviceToken);
        setIsConnected(true);
      }
      const apiUrl = await kindleService.getTlsClientApiUrl();
      if (apiUrl) {
        setTlsApiUrl(apiUrl);
      }
      const syncInfo = await kindleService.getLastSyncInfo();
      setLastSync(syncInfo.lastSync);
      setSyncStatus(syncInfo.status);
    };
    loadCredentials();
  }, []);

  const handleSaveCredentials = async () => {
    if (!cookies.trim()) {
      setError('Amazon cookies are required');
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      await kindleService.saveCredentials({
        cookies: cookies.trim(),
        deviceToken: deviceToken.trim(),
      });
      // Also save TLS API URL if provided
      await kindleService.saveTlsClientApiUrl(tlsApiUrl.trim());
      setIsConnected(true);
      setError(null);
    } catch (err) {
      setError('Failed to save credentials');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDisconnect = async () => {
    if (confirm('Disconnect Kindle? Your sync history will be preserved.')) {
      await kindleService.clearCredentials();
      setCookies('');
      setDeviceToken('');
      setIsConnected(false);
      setLastSync(null);
    }
  };

  const handleSync = async () => {
    setIsSyncing(true);
    setError(null);

    try {
      const result = await kindleService.sync();
      if (result.success) {
        setSyncStatus('success');
        setLastSync(new Date());
      } else {
        setError(result.error || 'Sync failed');
        setSyncStatus('error');
      }
    } catch (err) {
      setError('Sync failed');
      setSyncStatus('error');
    } finally {
      setIsSyncing(false);
    }
  };

  const handleExport = async () => {
    if (!db) return;

    const data = {
      exportedAt: new Date().toISOString(),
      version: '1.0',
      books: await db.books.toArray(),
      readingSessions: await db.readingSessions.toArray(),
      goals: await db.goals.toArray(),
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `raquel-reads-export-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleImport = async () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = async (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file || !db) return;

      try {
        const text = await file.text();
        const data = JSON.parse(text);

        if (data.books) {
          for (const book of data.books) {
            const existing = await db.books.get(book.id);
            if (!existing) {
              await db.books.add(book);
            }
          }
        }

        if (data.readingSessions) {
          for (const session of data.readingSessions) {
            const existing = await db.readingSessions.get(session.id);
            if (!existing) {
              await db.readingSessions.add(session);
            }
          }
        }

        if (data.goals) {
          for (const goal of data.goals) {
            const existing = await db.goals.get(goal.id);
            if (!existing) {
              await db.goals.add(goal);
            }
          }
        }

        alert('Data imported successfully!');
      } catch (err) {
        alert('Failed to import data. Make sure the file is valid.');
      }
    };
    input.click();
  };

  const handleClearData = async () => {
    if (!db) return;

    if (confirm('Are you sure you want to delete ALL your data? This cannot be undone!')) {
      if (confirm('Really delete everything? Export your data first if you want to keep it.')) {
        await db.books.clear();
        await db.readingSessions.clear();
        await db.goals.clear();
        await db.syncLogs.clear();
        await db.kindleSnapshots.clear();
        window.location.reload();
      }
    }
  };

  return (
    <div className="container max-w-2xl py-4 sm:py-6">
      <div className="mb-4 sm:mb-6">
        <h1 className="text-xl font-bold tracking-tight sm:text-2xl">Settings</h1>
        <p className="text-sm text-muted-foreground sm:text-base">Manage your account and preferences</p>
      </div>

      {/* Kindle Integration */}
      <Card className="mb-4 sm:mb-6">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Cloud className="h-5 w-5" />
              <CardTitle className="text-base">Kindle Integration</CardTitle>
            </div>
            <Badge variant={isConnected ? 'default' : 'secondary'}>
              {isConnected ? 'Connected' : 'Not Connected'}
            </Badge>
          </div>
          <CardDescription>
            Sync your Kindle library and reading activity automatically
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Setup info */}
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 dark:border-amber-900 dark:bg-amber-950">
            <div className="flex gap-3">
              <AlertTriangle className="h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
              <div className="text-sm">
                <p className="font-medium text-amber-800 dark:text-amber-200">Setup Required</p>
                <p className="text-amber-700 dark:text-amber-300">
                  Run the tls-client-api server first:{' '}
                  <code className="rounded bg-amber-100 px-1 dark:bg-amber-900">docker-compose up -d</code>
                </p>
                <Button
                  variant="link"
                  size="sm"
                  className="h-auto p-0 text-amber-700 dark:text-amber-300"
                  onClick={() => setShowInstructions(true)}
                >
                  <HelpCircle className="mr-1 h-3 w-3" />
                  How to get cookies
                </Button>
              </div>
            </div>
          </div>

          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950 dark:text-red-300">
              {error}
            </div>
          )}

          {/* Credentials form */}
          <div className="space-y-3">
            <div>
              <label htmlFor="cookies" className="mb-1.5 block text-sm font-medium">
                Amazon Cookies
              </label>
              <Input
                id="cookies"
                type="password"
                placeholder="ubid-main=xxx; at-main=xxx; x-main=xxx; session-id=xxx"
                value={cookies}
                onChange={(e) => setCookies(e.target.value)}
              />
              <p className="mt-1 text-xs text-muted-foreground">
                Required cookies: ubid-main, at-main, x-main, session-id
              </p>
            </div>

            <div>
              <label htmlFor="deviceToken" className="mb-1.5 block text-sm font-medium">
                Device Token (optional)
              </label>
              <Input
                id="deviceToken"
                type="password"
                placeholder="Your Kindle device token"
                value={deviceToken}
                onChange={(e) => setDeviceToken(e.target.value)}
              />
            </div>

            <Separator />

            <div>
              <div className="mb-1.5 flex items-center justify-between">
                <label htmlFor="tlsApiUrl" className="text-sm font-medium">
                  TLS Client API URL (for mobile)
                </label>
                <Button
                  variant="link"
                  size="sm"
                  className="h-auto p-0 text-xs"
                  onClick={() => setShowDeployInstructions(true)}
                >
                  <Server className="mr-1 h-3 w-3" />
                  Deploy your own
                </Button>
              </div>
              <Input
                id="tlsApiUrl"
                type="url"
                placeholder="https://your-tls-api.railway.app (leave blank for localhost)"
                value={tlsApiUrl}
                onChange={(e) => setTlsApiUrl(e.target.value)}
              />
              <p className="mt-1 text-xs text-muted-foreground">
                Required for mobile access. Deploy tls-client-api to a cloud service.
              </p>
            </div>

            <div className="flex gap-2">
              <Button onClick={handleSaveCredentials} disabled={isSaving} className="flex-1">
                {isSaving ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Saving...
                  </>
                ) : isConnected ? (
                  <>
                    <CheckCircle className="mr-2 h-4 w-4" />
                    Update Credentials
                  </>
                ) : (
                  'Save Credentials'
                )}
              </Button>
              {isConnected && (
                <Button variant="outline" onClick={handleDisconnect}>
                  Disconnect
                </Button>
              )}
            </div>
          </div>

          {/* Sync status */}
          {isConnected && (
            <>
              <Separator />
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium">Sync Status</p>
                  <p className="text-xs text-muted-foreground">
                    {lastSync
                      ? `Last synced ${formatDistanceToNow(lastSync, { addSuffix: true })}`
                      : 'Never synced'}
                  </p>
                </div>
                <Button onClick={handleSync} disabled={isSyncing} size="sm">
                  {isSyncing ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Syncing...
                    </>
                  ) : (
                    <>
                      <RefreshCw className="mr-2 h-4 w-4" />
                      Sync Now
                    </>
                  )}
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Data Management */}
      <Card className="mb-4 sm:mb-6">
        <CardHeader>
          <CardTitle className="text-base">Data Management</CardTitle>
          <CardDescription>Export or import your reading data</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-900 dark:bg-blue-950">
            <div className="flex gap-3">
              <AlertTriangle className="h-5 w-5 shrink-0 text-blue-600 dark:text-blue-400" />
              <div className="text-sm">
                <p className="font-medium text-blue-800 dark:text-blue-200">Browser Storage</p>
                <p className="text-blue-700 dark:text-blue-300">
                  Your data is stored locally in this browser. Export regularly to avoid data loss.
                </p>
              </div>
            </div>
          </div>

          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={handleExport}>
              <Download className="mr-2 h-4 w-4" />
              Export Data
            </Button>
            <Button variant="outline" className="flex-1" onClick={handleImport}>
              <Upload className="mr-2 h-4 w-4" />
              Import Data
            </Button>
          </div>

          <Separator />

          <div>
            <p className="mb-2 text-sm font-medium text-destructive">Danger Zone</p>
            <Button variant="destructive" size="sm" onClick={handleClearData}>
              <Trash2 className="mr-2 h-4 w-4" />
              Clear All Data
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* About */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">About</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">Raquel Reads v0.1.0</p>
          <p className="text-sm text-muted-foreground">
            A personal reading tracker with Kindle integration.
          </p>
        </CardContent>
      </Card>

      {/* Instructions Dialog */}
      <Dialog open={showInstructions} onOpenChange={setShowInstructions}>
        <DialogContent className="max-h-[80vh] overflow-y-auto sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>How to Get Amazon Cookies</DialogTitle>
            <DialogDescription>
              Follow these steps to extract your Amazon cookies
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 text-sm">
            <div>
              <h4 className="font-medium">1. Start the TLS Client Server</h4>
              <p className="text-muted-foreground">
                Open a terminal in the project folder and run:
              </p>
              <code className="mt-1 block rounded bg-muted p-2">docker-compose up -d</code>
              <p className="mt-1 text-xs text-muted-foreground">
                (or <code>docker compose up -d</code> on newer Docker)
              </p>
            </div>

            <div>
              <h4 className="font-medium">2. Log in to Amazon</h4>
              <p className="text-muted-foreground">
                Go to{' '}
                <a
                  href="https://read.amazon.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary underline"
                >
                  read.amazon.com
                </a>{' '}
                and sign in with your Amazon account.
              </p>
            </div>

            <div>
              <h4 className="font-medium">3. Open Developer Tools</h4>
              <p className="text-muted-foreground">
                Press <kbd className="rounded border px-1">F12</kbd> or right-click and select
                &quot;Inspect&quot;
              </p>
            </div>

            <div>
              <h4 className="font-medium">4. Go to Application Tab</h4>
              <p className="text-muted-foreground">
                Click on &quot;Application&quot; (or &quot;Storage&quot; in Firefox), then
                &quot;Cookies&quot; → &quot;https://read.amazon.com&quot;
              </p>
            </div>

            <div>
              <h4 className="font-medium">5. Copy ALL Cookies</h4>
              <p className="text-muted-foreground">
                Copy ALL cookie values from read.amazon.com. Right-click in the cookies list
                and select &quot;Copy all&quot; or manually copy each one in this format:
              </p>
              <code className="mt-1 block rounded bg-muted p-2 text-xs">
                name1=value1; name2=value2; ...
              </code>
            </div>

            <div>
              <h4 className="font-medium">6. Get Device Token (Required)</h4>
              <p className="text-muted-foreground">
                Go to the <strong>Network</strong> tab in DevTools, refresh the page, then search for
                &quot;getDeviceToken&quot;. Click that request and copy the value from the URL:
              </p>
              <code className="mt-1 block rounded bg-muted p-2 text-xs break-all">
                .../getDeviceToken?serialNumber=<strong>XXXXX</strong>&amp;deviceType=XXXXX
              </code>
              <p className="mt-1 text-muted-foreground">
                The serialNumber value is your device token.
              </p>
            </div>

            <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 dark:border-amber-900 dark:bg-amber-950">
              <p className="text-xs text-amber-700 dark:text-amber-300">
                <strong>Note:</strong> Cookies expire periodically. If sync stops working,
                you&apos;ll need to repeat this process.
              </p>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Deploy Instructions Dialog */}
      <Dialog open={showDeployInstructions} onOpenChange={setShowDeployInstructions}>
        <DialogContent className="max-h-[80vh] overflow-y-auto sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Deploy TLS Client API</DialogTitle>
            <DialogDescription>
              Host the API server for mobile access
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 text-sm">
            <div className="rounded-lg border border-blue-200 bg-blue-50 p-3 dark:border-blue-900 dark:bg-blue-950">
              <p className="text-blue-700 dark:text-blue-300">
                <strong>Why is this needed?</strong> The TLS Client API bypasses Amazon&apos;s
                TLS fingerprinting. For mobile access, you need to host it in the cloud.
              </p>
            </div>

            <div>
              <h4 className="font-medium">Option 1: Fly.io (Recommended - Free Tier)</h4>
              <p className="text-muted-foreground mb-2">
                Fly.io offers a generous free tier with 3 shared VMs.
              </p>
              <ol className="list-decimal ml-4 space-y-1 text-muted-foreground">
                <li>Install Fly CLI: <code className="rounded bg-muted px-1">curl -L https://fly.io/install.sh | sh</code></li>
                <li>Login: <code className="rounded bg-muted px-1">fly auth login</code></li>
                <li>Create a new app in the project folder</li>
                <li>Deploy with: <code className="rounded bg-muted px-1">fly deploy --image lfsaga/tls-client-api:0.0.1</code></li>
                <li>Set the auth key: <code className="rounded bg-muted px-1">fly secrets set AUTH_KEYS=raquel-reads-key</code></li>
              </ol>
            </div>

            <div>
              <h4 className="font-medium">Option 2: Railway (~$5/month)</h4>
              <p className="text-muted-foreground mb-2">
                Simple deployment with usage-based pricing.
              </p>
              <ol className="list-decimal ml-4 space-y-1 text-muted-foreground">
                <li>Go to <a href="https://railway.app" target="_blank" rel="noopener noreferrer" className="text-primary underline">railway.app</a></li>
                <li>Create new project → Deploy Docker Image</li>
                <li>Enter: <code className="rounded bg-muted px-1">lfsaga/tls-client-api:0.0.1</code></li>
                <li>Add variable: <code className="rounded bg-muted px-1">AUTH_KEYS=raquel-reads-key</code></li>
                <li>Generate domain and copy the URL</li>
              </ol>
            </div>

            <div>
              <h4 className="font-medium">After Deployment</h4>
              <p className="text-muted-foreground">
                Copy your deployed URL (e.g., <code className="rounded bg-muted px-1">https://your-app.fly.dev</code>)
                and paste it in the &quot;TLS Client API URL&quot; field above.
              </p>
            </div>

            <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 dark:border-amber-900 dark:bg-amber-950">
              <p className="text-xs text-amber-700 dark:text-amber-300">
                <strong>Security:</strong> Your Amazon cookies are sent to this API server.
                Only use a server you control and trust.
              </p>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
