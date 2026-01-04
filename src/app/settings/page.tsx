'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Cloud, Download, Upload, Trash2, AlertTriangle } from 'lucide-react';

export default function SettingsPage() {
  return (
    <div className="container max-w-2xl py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">
          Manage your account and preferences
        </p>
      </div>

      {/* Kindle Integration */}
      <Card className="mb-6">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Cloud className="h-5 w-5" />
              <CardTitle className="text-base">Kindle Integration</CardTitle>
            </div>
            <Badge variant="secondary">Not Connected</Badge>
          </div>
          <CardDescription>
            Sync your Kindle library and reading activity automatically
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 dark:border-amber-900 dark:bg-amber-950">
            <div className="flex gap-3">
              <AlertTriangle className="h-5 w-5 text-amber-600 dark:text-amber-400" />
              <div className="text-sm">
                <p className="font-medium text-amber-800 dark:text-amber-200">Setup Required</p>
                <p className="text-amber-700 dark:text-amber-300">
                  You&apos;ll need to run the tls-client-api server and provide your Amazon cookies to enable Kindle sync.
                </p>
              </div>
            </div>
          </div>

          <div className="space-y-3">
            <div>
              <label htmlFor="cookies" className="mb-1.5 block text-sm font-medium">
                Amazon Cookies
              </label>
              <Input
                id="cookies"
                type="password"
                placeholder="ubid-main=xxx; at-main=xxx; x-main=xxx; session-id=xxx"
              />
              <p className="mt-1 text-xs text-muted-foreground">
                Paste your Amazon cookies (ubid-main, at-main, x-main, session-id)
              </p>
            </div>

            <div>
              <label htmlFor="deviceToken" className="mb-1.5 block text-sm font-medium">
                Device Token
              </label>
              <Input
                id="deviceToken"
                type="password"
                placeholder="Your Kindle device token"
              />
            </div>

            <div className="flex gap-2">
              <Button className="flex-1">Save & Test Connection</Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Data Management */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="text-base">Data Management</CardTitle>
          <CardDescription>
            Export or import your reading data
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-900 dark:bg-blue-950">
            <div className="flex gap-3">
              <AlertTriangle className="h-5 w-5 text-blue-600 dark:text-blue-400" />
              <div className="text-sm">
                <p className="font-medium text-blue-800 dark:text-blue-200">Browser Storage</p>
                <p className="text-blue-700 dark:text-blue-300">
                  Your data is stored locally in this browser. Export regularly to avoid data loss.
                </p>
              </div>
            </div>
          </div>

          <div className="flex gap-2">
            <Button variant="outline" className="flex-1">
              <Download className="mr-2 h-4 w-4" />
              Export Data
            </Button>
            <Button variant="outline" className="flex-1">
              <Upload className="mr-2 h-4 w-4" />
              Import Data
            </Button>
          </div>

          <Separator />

          <div>
            <p className="mb-2 text-sm font-medium text-destructive">Danger Zone</p>
            <Button variant="destructive" size="sm">
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
          <p className="text-sm text-muted-foreground">
            Raquel Reads v0.1.0
          </p>
          <p className="text-sm text-muted-foreground">
            A personal reading tracker with Kindle integration.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
