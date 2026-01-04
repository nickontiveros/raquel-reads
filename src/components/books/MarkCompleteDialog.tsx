'use client';

import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { CheckCircle } from 'lucide-react';
import { bookService } from '@/lib/services/bookService';
import { format } from 'date-fns';

interface MarkCompleteDialogProps {
  bookId: string;
  bookTitle: string;
  onComplete?: () => void;
  trigger?: React.ReactNode;
}

export function MarkCompleteDialog({ bookId, bookTitle, onComplete, trigger }: MarkCompleteDialogProps) {
  const [open, setOpen] = useState(false);
  const [completedDate, setCompletedDate] = useState<Date>(new Date());
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleComplete = async () => {
    setIsSubmitting(true);
    try {
      await bookService.update(bookId, {
        status: 'completed',
        completedAt: completedDate,
      });
      setOpen(false);
      onComplete?.();
    } catch (error) {
      console.error('Failed to mark book as complete:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger || (
          <Button variant="outline">
            <CheckCircle className="mr-2 h-4 w-4" />
            Mark Complete
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[400px]">
        <DialogHeader>
          <DialogTitle>Mark as Complete</DialogTitle>
          <DialogDescription>
            When did you finish reading &quot;{bookTitle}&quot;?
          </DialogDescription>
        </DialogHeader>

        <div className="mt-4 space-y-4">
          <div>
            <label htmlFor="completedDate" className="mb-1.5 block text-sm font-medium">
              Completion Date
            </label>
            <Input
              id="completedDate"
              type="date"
              value={format(completedDate, 'yyyy-MM-dd')}
              onChange={(e) => setCompletedDate(new Date(e.target.value + 'T12:00:00'))}
              max={format(new Date(), 'yyyy-MM-dd')}
            />
          </div>

          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => setOpen(false)}
              className="flex-1"
            >
              Cancel
            </Button>
            <Button
              onClick={handleComplete}
              disabled={isSubmitting}
              className="flex-1"
            >
              {isSubmitting ? 'Saving...' : 'Mark Complete'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
